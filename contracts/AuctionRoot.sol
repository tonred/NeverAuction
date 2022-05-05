pragma ton-solidity >= 0.57.3;

pragma AbiHeader time;
pragma AbiHeader expire;
pragma AbiHeader pubkey;

import "./interfaces/external/IAggregator.sol";
import "./interfaces/internal/IAuctionRoot.sol";
import "./interfaces/internal/IElector.sol";
import "./interfaces/internal/IUpgradable.sol";
import "./platform/PlatformUtils.sol";
import "./structures/AuctionConfig.sol";
import "./structures/DeAuctionConfig.sol";
import "./utils/Constants.sol";
import "./utils/ErrorCodes.sol";
import "./utils/Gas.sol";
import "./utils/TransferUtils.sol";

import "@broxus/contracts/contracts/utils/RandomNonce.sol";


contract AuctionRoot is IAuctionRoot, IUpgradable, PlatformUtils, TransferUtils, RandomNonce {
    event ElectorChange(address from, address to);
    event AuctionConfigChange(AuctionConfig from, AuctionConfig to);
    event DeAuctionGlobalConfigChange(DeAuctionGlobalConfig from, DeAuctionGlobalConfig to);

    event NewAuction(address auction);
    event NewDeParticipant(address deParticipant);
    event NewDeAuction(address auction, address deAuction);
    event Finish(bool success, BidData winner);

    address public _elector;
    AuctionConfig public _auctionConfig;
    DeAuctionGlobalConfig public _deAuctionGlobalConfig;

    uint64 public _nonce;
    bool public _isActionNow;
    address public _auction;

    TvmCell public _auctionCode;
    TvmCell public _deAuctionCode;
    TvmCell public _deParticipantCode;


    modifier onlyElector() {
        require(msg.sender == _elector, ErrorCodes.IS_NOT_ELECTOR);
        _;
    }

    modifier onlyAuction() {
        require(_isActionNow && msg.sender == _auction, ErrorCodes.IS_NOT_AUCTION);
        _;
    }

    modifier onlyDeParticipant(address owner) {
        address deParticipant = _deParticipantAddress(address(this), owner);
        require(msg.sender == deParticipant, ErrorCodes.IS_NOT_DE_PARTICIPANT);
        _;
    }


    constructor(address elector, AuctionConfig auctionConfig, DeAuctionGlobalConfig deAuctionGlobalConfig) public {
        tvm.accept();
        _elector = elector;
        _auctionConfig = auctionConfig;
        _deAuctionGlobalConfig = deAuctionGlobalConfig;
    }


    function expectedAuction(uint64 nonce) public view responsible override returns (address auction) {
        return {value: 0, flag: MsgFlag.REMAINING_GAS, bounce: false} _auctionAddress(address(this), nonce);
    }

    function expectedDeParticipant(address owner) public view responsible override returns (address deParticipant) {
        return {value: 0, flag: MsgFlag.REMAINING_GAS, bounce: false} _deParticipantAddress(address(this), owner);
    }

    function expectedDeAuction(uint64 nonce) public view responsible override returns (address deAuction) {
        return {value: 0, flag: MsgFlag.REMAINING_GAS, bounce: false} _deAuctionAddress(address(this), nonce);
    }

    function expectedAuctionHashCode(address auction) public view responsible override returns (uint256 hash) {
        TvmCell code = _calcDeAuctionCode(auction);
        return {value: 0, flag: MsgFlag.REMAINING_GAS, bounce: false} tvm.hash(code);
    }

    function expectedBidHashCode(address auction, address owner) public view responsible override returns (uint256 hash) {
        TvmCell salt = abi.encode(auction, owner);
        TvmCell code = tvm.setCodeSalt(_auctionConfig.bidCode, salt);
        return {value: 0, flag: MsgFlag.REMAINING_GAS, bounce: false} tvm.hash(code);
    }

    function getDetails() public view responsible override returns (address elector, AuctionConfig auctionConfig, DeAuctionGlobalConfig deAuctionGlobalConfig) {
        return {value: 0, flag: MsgFlag.REMAINING_GAS, bounce: false} (_elector, _auctionConfig, _deAuctionGlobalConfig);
    }

    function getCodes() public view responsible override returns (TvmCell auctionCode, TvmCell deAuctionCode, TvmCell deParticipantCode) {
        return {value: 0, flag: MsgFlag.REMAINING_GAS, bounce: false} (_auctionCode, _deAuctionCode, _deParticipantCode);
    }

    function currentAuction() public view responsible override returns (optional(address) auction) {
        if (_isActionNow) {
            auction.set(_auction);
        }
        return {value: 0, flag: MsgFlag.REMAINING_GAS, bounce: false} auction;
    }


    function setCodes(
        TvmCell platformCode,
        TvmCell auctionCode,
        TvmCell deAuctionCode,
        TvmCell deParticipantCode
    ) public override onlyElector cashBack {
        _platformCode = platformCode;
        _auctionCode = auctionCode;
        _deAuctionCode = deAuctionCode;
        _deParticipantCode = deParticipantCode;
    }

    function changeElector(address elector) public override onlyElector cashBack {
        emit ElectorChange(_elector, elector);
        _elector = elector;
    }

    function changeAuctionConfig(AuctionConfig auctionConfig) public override onlyElector cashBack {
        emit AuctionConfigChange(_auctionConfig, auctionConfig);
        _auctionConfig = auctionConfig;
    }

    function changeDeAuctionGlobalConfig(DeAuctionGlobalConfig deAuctionGlobalConfig) public override onlyElector cashBack {
        emit DeAuctionGlobalConfigChange(_deAuctionGlobalConfig, deAuctionGlobalConfig);
        _deAuctionGlobalConfig = deAuctionGlobalConfig;
    }


    function createAuction(uint128 minLotSize, uint128 quotingPrice) public override onlyElector cashBack {
        require(!_isActionNow, ErrorCodes.ALREADY_RUNNING);
        require(_auctionConfig.fee > Gas.DEPLOY_BID_VALUE, ErrorCodes.LOW_FEE_VALUE);
        require(_auctionConfig.deposit > _auctionConfig.fee, ErrorCodes.LOW_DEPOSIT_VALUE);
        TvmCell stateInit = _buildAuctionStateInit(address(this), _nonce++);
        TvmCell initialParams = abi.encode(_auctionConfig, minLotSize, quotingPrice);
        _auction = new Platform{
            stateInit: stateInit,
            value: Gas.DEPLOY_AUCTION_VALUE,
            flag: MsgFlag.SENDER_PAYS_FEES,
            bounce: false
        }(_auctionCode, initialParams, address(0));
        emit NewAuction(_auction);
        _isActionNow = true;
    }

    function createDeParticipant() public override cashBack {
        TvmCell stateInit = _buildDeParticipantStateInit(address(this), msg.sender);
        TvmCell initialParams;
        address deParticipant = new Platform{
            stateInit: stateInit,
            value: Gas.DEPLOY_DE_PARTICIPANT_VALUE,
            flag: MsgFlag.SENDER_PAYS_FEES,
            bounce: false
        }(_deParticipantCode, initialParams, address(0));
        emit NewDeParticipant(deParticipant);
    }

    function createDeAuction(address owner, DeAuctionInitConfig initConfig) public override onlyDeParticipant(owner) {
        DeAuctionErrorReason error;
        if (!_isActionNow) error = DeAuctionErrorReason.NO_ACTIVE_AUCTION;
        if (initConfig.prices.min > initConfig.prices.max) error = DeAuctionErrorReason.WRONG_PRICE_RANGE;
        if (initConfig.description.byteLength() > Constants.MAX_STRING_LENGTH) error = DeAuctionErrorReason.TOO_LONG_DESCRIPTION;

        if (error != DeAuctionErrorReason.OK) {
            IAggregator(initConfig.aggregator).onCreateDeAuctionException{
                value: 0,
                flag: MsgFlag.REMAINING_GAS,
                bounce: false
            }(error);
            return;
        }

        DeAuctionConfig config = DeAuctionConfig(initConfig, _deAuctionGlobalConfig);
        TvmCell stateInit = _buildDeAuctionStateInit(address(this), _nonce++);
        TvmCell initialParams = abi.encode(_auction, config);
        TvmCell deAuctionCode = _calcDeAuctionCode(_auction);
        address deAuction = new Platform{
            stateInit: stateInit,
            value: 0,
            flag: MsgFlag.REMAINING_GAS,
            bounce: false
        }(deAuctionCode, initialParams, address(0));
        emit NewDeAuction(_auction, deAuction);
    }

    function onFinish(bool success, BidData winner) public override onlyAuction {
        _isActionNow = false;
        emit Finish(success, winner);
        IElector(_elector).onAuctionFinish{
            value: 0,
            flag: MsgFlag.REMAINING_GAS,
            bounce: false
        }(success, winner.owner, winner.price, winner.amount);
    }

    function upgrade(TvmCell code) external override internalMsg {
        emit CodeUpgraded();
        TvmCell data = abi.encode(
            _elector, _nonce, _auctionConfig, _deAuctionGlobalConfig, _isActionNow, _auction,
            _auctionCode, _deAuctionCode, _deParticipantCode  // codes
        );
        tvm.setcode(code);
        tvm.setCurrentCode(code);
        onCodeUpgrade(data);
    }

    function _calcDeAuctionCode(address auction) private view returns (TvmCell) {
        TvmCell salt = abi.encode(auction);
        return tvm.setCodeSalt(_deAuctionCode, salt);
    }

    function onCodeUpgrade(TvmCell data) private {
        (
            _elector, _nonce, _auctionConfig, _deAuctionGlobalConfig, _isActionNow, _auction,
            _auctionCode, _deAuctionCode, _deParticipantCode
        ) = abi.decode(data, (
            address, uint64, AuctionConfig, DeAuctionGlobalConfig, bool, address, TvmCell, TvmCell, TvmCell
        ));
    }

}
