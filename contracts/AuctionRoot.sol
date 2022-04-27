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


contract AuctionRoot is IAuctionRoot, IUpgradable, PlatformUtils, TransferUtils {
    event NewAuction(address auction);
    event NewDeParticipant(address deParticipant);
    event NewDeAuction(address auction, address deAuction);

    address public static _elector;

    uint64 public _nonce;
    AuctionConfig public _auctionConfig;
    DeAuctionGlobalConfig public _deAuctionGlobalConfig;
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
        address deParticipant = _deParticipantAddress(owner);
        require(msg.sender == deParticipant, ErrorCodes.IS_NOT_DE_PARTICIPANT);
        _;
    }


    constructor(AuctionConfig auctionConfig, DeAuctionGlobalConfig deAuctionGlobalConfig) public onlyElector {
        _auctionConfig = auctionConfig;
        _deAuctionGlobalConfig = deAuctionGlobalConfig;
    }


    function expectedDeParticipant(address owner) public view responsible override returns (address deParticipant) {
        return {value: 0, flag: MsgFlag.REMAINING_GAS, bounce: false} _deParticipantAddress(owner);
    }

    function currentAuction() public view responsible override returns (optional(address) auction) {
        if (_isActionNow) {
            auction.set(_auction);
        }
        return {value: 0, flag: MsgFlag.REMAINING_GAS, bounce: false} auction;
    }

    // todo getCodes, getParameters
    // todo find and replace all ' : '

    function changeAuctionConfig(AuctionConfig auctionConfig) public override onlyElector {
        _auctionConfig = auctionConfig;
    }

    function changeDeAuctionGlobalConfig(DeAuctionGlobalConfig deAuctionGlobalConfig) public override onlyElector {
        _deAuctionGlobalConfig = deAuctionGlobalConfig;
    }

    function createAuction(uint128 minLotSize, uint128 quotingPrice) public override cashBack {
        require(!_isActionNow, ErrorCodes.AUCTION_IS_ALREADY_RUNNING);
        TvmCell stateInit = _buildAuctionStateInit(_nonce++);
        TvmCell initialParams = abi.encode(_auctionConfig, minLotSize, quotingPrice);
        _auction = new Platform{
            stateInit: stateInit,
            value: Gas.DEPLOY_AUCTION_VALUE
        }(_auctionCode, initialParams, address(0));
        emit NewAuction(_auction);
        _isActionNow = true;
    }

    function createDeParticipant() public override cashBack {
        TvmCell stateInit = _buildDeParticipantStateInit(msg.sender);
        TvmCell initialParams;
        address deParticipant = new Platform{
            stateInit: stateInit,
            value: Gas.DEPLOY_DE_PARTICIPANT_VALUE
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
        TvmCell stateInit = _buildDeAuctionStateInit(_nonce++);
        TvmCell initialParams = abi.encode(_auction, config);
        address deAuction = new Platform{
            stateInit: stateInit,
            value: 0,
            flag: MsgFlag.REMAINING_GAS,
            bounce: false
        }(_deAuctionCode, initialParams, address(0));
        emit NewDeAuction(_auction, deAuction);
    }

    function onFinish(bool success, BidData winner) public override onlyAuction {
        IElector(_elector).onAuctionFinish{
            value: MsgFlag.REMAINING_GAS,
            flag: 0,
            bounce: false
        }(success, winner.owner, winner.price, winner.amount);
        _isActionNow = false;
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

    function onCodeUpgrade(TvmCell data) private {
        (
            _elector, _nonce, _auctionConfig, _deAuctionGlobalConfig, _isActionNow, _auction,
            _auctionCode, _deAuctionCode, _deParticipantCode
        ) = abi.decode(data, (
            address, uint64, AuctionConfig, DeAuctionGlobalConfig, bool, address, TvmCell, TvmCell, TvmCell
        ));
    }

}
