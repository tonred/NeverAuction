pragma ton-solidity >= 0.57.3;

pragma AbiHeader time;
pragma AbiHeader expire;
pragma AbiHeader pubkey;

import "./interfaces/external/IAggregator.sol";
import "./interfaces/internal/IElector.sol";
import "./interfaces/internal/IUpgradable.sol";
import "./platform/PlatformUtils.sol";
import "./structures/DeAuctionConfig.sol";
import "Auction.sol";


contract AuctionRoot is IAuctionRoot, IUpgradable, PlatformUtils, TransferUtils {
    event NewAuction(address auction);
    event NewDeAuction(address auction, address deAuction);

    address static _elector;

    uint64 public _nonce;
    AuctionConfig public _config;
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


    constructor(AuctionConfig config) public onlyElector {
        _config = config;
    }


    function expectedDeParticipant(address owner) public view responsible override returns (address deParticipant) {
        return {value: 0, flag: MsgFlag.REMAINING_GAS, bounce: false} _deParticipantAddress(owner);
    }

    function currentAuction() public responsible override returns (optional(address) auction) {
        if (_isActionNow) {
            auction.set(_auction);
        }
        return {value: 0, flag: MsgFlag.REMAINING_GAS, bounce: false} auction;
    }

    // todo getCodes, getParameters
    // todo find and replace all ' : '

    function changeConfiguration(AuctionConfig config) public override onlyElector {
        _config = config;
    }

    function createAuction(uint128 minLotSize, uint128 quotingPrice) public override cashBack {
        require(!_isActionNow, ErrorCodes.AUCTION_IS_ALREADY_RUNNING);
        TvmCell stateInit = _buildAuctionStateInit(_nonce++);
        _auction = new Auction{
            stateInit: stateInit,
            value: Gas.DEPLOY_AUCTION_VALUE
        }(_config, minLotSize, quotingPrice);
        emit NewAuction(_auction);
        _isActionNow = true;
    }

    function createDeAuction(address owner, DeAuctionConfig config) public override onlyDeParticipant(owner) {
        DeAuctionErrorReason error;
        if (!_isActionNow) error = DeAuctionErrorReason.NO_ACTIVE_AUCTION;
        if (config.prices.min > config.prices.max) error = DeAuctionErrorReason.WRONG_PRICE_RANGE;
        if (config.description.byteLength() > Constants.MAX_STRING_LENGTH) error = DeAuctionErrorReason.TOO_LONG_DESCRIPTION;

        if (error != DeAuctionErrorReason.OK) {
            IAggregator(config.aggregator).onCreateDeAuctionException{
                value: 0,
                flag: MsgFlag.REMAINING_GAS,
                bounce: false
            }(error);
            return;
        }

        // todo platform
        // todo create de participant
//        TvmCell stateInit = _buildDeAuctionStateInit(_nonce++);
//        address deAuction = new DeAuction{
//            stateInit: stateInit,
//            value: 0,
//            flag: MsgFlag.REMAINING_GAS,
//            bounce: false
//        }(config);
//        emit NewDeAuction(_auction, deAuction);
    }

    function onFinish(bool success, BidData winner) public override onlyAuction {
        IElector(_elector).onAuctionFinish{
            value: MsgFlag.REMAINING_GAS,
            flag: 0,
            bounce: false
        }(success, winner.owner, winner.price, winner.amount);
        _isActionNow = false;
    }

    function _buildAuctionStateInit(uint64 nonce) private view returns (TvmCell) {
        return tvm.buildStateInit({
            contr: Auction,
            varInit: {
                _root: address(this),
                _nonce: nonce
            },
            pubkey: 0,
            code: _auctionCode
        });
    }

    function upgrade(TvmCell code) external override internalMsg {
        // todo
    }

}
