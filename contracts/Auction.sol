pragma ton-solidity >= 0.57.3;

pragma AbiHeader time;
pragma AbiHeader expire;
pragma AbiHeader pubkey;

import "./interfaces/external/IParticipant.sol";
import "./interfaces/internal/IAuction.sol";
import "./interfaces/internal/IAuctionRoot.sol";
import "./platform/PlatformUtils.sol";
import "./structures/AuctionConfig.sol";
import "./utils/Constants.sol";
import "./utils/ErrorCodes.sol";
import "./utils/Gas.sol";
import "./utils/HashUtils.sol";
import "./utils/TransferUtils.sol";
import "Bid.sol";


contract Auction is IAuction, PlatformUtils, HashUtils, TransferUtils {
    event MakeBid(address owner, uint256 hash);
    event RemoveBid(address owner, uint256 hash);
    event ConfirmBid(address owner, uint256 hash);
    event Finish(bool success, BidData winner);

    address public static _root;
    uint64 public static _nonce;

    uint128 public _minLotSize;
    uint128 public _quotingPrice;

    uint128 public _fee;
    uint128 public _deposit;
    TvmCell public _bidCode;

    Phase public _phase;
    uint32 public _deBidTime;
    uint32 public _confirmTime;
    uint32 public _finishTime;

    uint64 _bidsCount;
    uint64 _confirmBidsCount;

    BidData public _winner;
    BidData _first;
    BidData _second;


    modifier onlyAuctionRoot() {
        require(msg.sender == _root, ErrorCodes.IS_NOT_ACTION_ROOT);
        _;
    }

    modifier onlyDeAuction(uint64 nonce) {
        address deAuction = _deAuctionAddress(nonce);
        require(msg.sender == deAuction, 69);
        _;
    }

    modifier withUpdate() {
        // todo maybe trigger finish from outside ?
        bool process = _update();
        if (process) {
            _;
        } else {
            msg.sender.transfer({value: 0, flag: MsgFlag.REMAINING_GAS, bounce: false});
        }
    }

    modifier inPhase(Phase phase) {
        require(_phase == phase, ErrorCodes.WRONG_PHASE);
        _;
    }

    modifier onlyBid(uint256 hash) {
        address bid = _bidAddress(hash);
        require(msg.sender == bid, ErrorCodes.IS_NOT_BID);
        _;
    }


    /*
    // todo
    @param fee                  Non-returnable fee value for each bid
    @param deposit              Returnable deposit value for each bid
    @param startTime            Timestamp when auction will start
    @param openDuration         Duration of open phase in seconds
    @param confirmDuration Duration of confirmation phase in seconds
    @param bidCode              Code of bid contract
    */
    function onCodeUpgrade(TvmCell input) private {
        tvm.resetStorage();
        TvmSlice slice = input.toSlice();
        (_root, /*type*/, /*remainingGasTo*/) = slice.decode(address, uint8, address);
        _platformCode = slice.loadRef();

        TvmCell initialData = slice.loadRef();
        _nonce = abi.decode(initialData, uint64);

        TvmCell initialParams = slice.loadRef();
        AuctionConfig config;
        (config, _minLotSize, _quotingPrice) = abi.decode(initialParams, (AuctionConfig, uint128, uint128));
        _fee = config.fee;
        _deposit = config.deposit;
        _bidCode = config.bidCode;

        _phase = Phase.OPEN;
        _deBidTime = now + config.openDuration;
        _confirmTime = _deBidTime + config.deBidDuration;
        _finishTime = _confirmTime + config.confirmDuration;
    }


    function getDetails() public view responsible override returns (AuctionDetails details) {
        details = AuctionDetails(_fee, _deposit, _deBidTime, _confirmTime, _finishTime, _minLotSize, _quotingPrice);
        return {value: 0, flag: MsgFlag.REMAINING_GAS, bounce: false} details;
    }

    function getPhase() public view responsible override returns (Phase phase) {
        return {value: 0, flag: MsgFlag.REMAINING_GAS, bounce: false} _phase;
    }

    function getWinner() public view responsible override returns (BidData winner) {
        return {value: 0, flag: MsgFlag.REMAINING_GAS, bounce: false} _winner;
    }


    /*
    Update phase, get phase before and after this update
    */
    function updateAndGetPhase() public responsible override returns (Phase before, Phase next) {
        before = _phase;
        _update();
        return {value: 0, flag: MsgFlag.REMAINING_GAS, bounce: false} (before, _phase);
    }

    /*
    Update phase of contract
    */
    function update() public override withUpdate {
        msg.sender.transfer({value: 0, flag: MsgFlag.REMAINING_GAS, bounce: false});
    }

    /*
    Make bid
    @param hash     Bid hash (can be calculated via `calcBidHash` method locally)
    @value          Must be greater than or equal to the deposit
    */
    function makeBid(uint256 hash) public override withUpdate inPhase(Phase.OPEN) {
        _makeBid(hash);
    }

    function makeDeBid(uint64 nonce, uint256 hash) public override onlyDeAuction(nonce) withUpdate inPhase(Phase.DE_BID) {
        _makeBid(hash);
    }

    function _makeBid(uint256 hash) private {
        require(msg.value >= _deposit, ErrorCodes.LOW_MSG_VALUE);
        TvmCell stateInit = _buildBidStateInit(hash);
        new Bid{
            stateInit: stateInit,
            value: Gas.DEPLOY_BID_VALUE
        }(msg.sender);
        emit MakeBid(msg.sender, hash);
        _bidsCount++;
        IParticipant(msg.sender).onMakeBid{
            value: msg.value - _deposit,
            flag: MsgFlag.SENDER_PAYS_FEES,
            bounce: false
        }();
    }

    /*
    Remove bid
    @param hash     Bid hash (can be calculated via `calcBidHash` method locally)
    @value          More than `Gas.REMOVE_BID_VALUE`
    */
    function removeBid(uint256 hash) public view override withUpdate inPhase(Phase.OPEN) cashBack {
        address bid = _bidAddress(hash);
        Bid(bid).remove{
            value: Gas.REMOVE_BID_VALUE,
            callback: onRemoveBid
        }();
        emit RemoveBid(msg.sender, hash);
    }

    function onRemoveBid(uint256 hash, address owner) public override onlyBid(hash) {
        _bidsCount--;
        IParticipant(owner).onRemoveBid{
            value: _deposit - _fee,
            flag: MsgFlag.SENDER_PAYS_FEES,
            bounce: false
        }();
    }

    /*
    Confirm bid
    @param price    Real price for 1 piece
    @param amount   Amount to buy
    @param salt     Random value that was used to calculate hash in `calcBidHash` method
    @value          You must send all value of your bid, can be calculated as [price * amount + fee - deposit]
    */
    function confirmBid(uint128 price, uint128 amount, uint256 salt) public view override withUpdate inPhase(Phase.CONFIRM) {
        require(price >= _quotingPrice, 69);
        require(amount >= _minLotSize, 69);
        uint128 value = price * amount;
        require(msg.value + _deposit >= value + _fee, ErrorCodes.LOW_MSG_VALUE);
        uint256 hash = calcBidHash(price, amount, msg.sender, salt);
        address bid = _bidAddress(hash);
        BidData data = BidData(msg.sender, price, amount, value);
        Bid(bid).confirm{
            value: Gas.CONFIRM_BID_VALUE,
            flag: MsgFlag.SENDER_PAYS_FEES,
            callback: onConfirmBid
        }(data, msg.value);
        emit ConfirmBid(msg.sender, hash);
    }

    function onConfirmBid(uint256 hash, BidData data, uint128 msgValue) public override onlyBid(hash) {
        uint128 returnValue = msgValue + _deposit - data.value - _fee;
        if (returnValue > 0) {
            IParticipant(data.owner).onConfirmBid{
                value: returnValue,
                flag: MsgFlag.SENDER_PAYS_FEES,
                bounce: false
            }();
        }
        _updateResults(data);
    }

    /*
    Calculates hash of bid
    Can be used off-chain before `makeBid` and `removeBid` functions
    @param price    Bid price (greater than or equal to quoting price)
    @param amount   Amount to buy (greater than or equal to min lot size)
    @param sender   Address of sender
    @param salt     Random 256-bit value (please use really random number)
    @return         256-bit hash
    */
    function calcBidHash(uint128 price, uint128 amount, address sender, uint256 salt) public view override returns (uint256 hash) {
        require(price >= _quotingPrice, 69);
        require(amount >= _minLotSize, 69);
        return _calcBidHash(price, amount, sender, salt);
    }

    function finish() public override {
//    function finish() public override withUpdate inPhase(Phase.FINISH) {
        // todo trigger it in DeAuction if winner == address(this)
        require(msg.sender == address(this), ErrorCodes.IS_NOT_SELF);
        bool success = true;
        if (_first.owner.value == 0) {
            // no winner
            success = false;
        } else if (_second.owner.value == 0) {
            // one winner (one bid)
            _winner = _first;
        } else {
            // one winner (many bids)
            uint128 returnValue = (_first.price - _second.price) * _first.amount;
            _first.owner.transfer({
                value: returnValue,
                flag: MsgFlag.SENDER_PAYS_FEES,
                bounce: false
            });
            _winner = _first;
            _winner.price = _second.price;
        }

        if (success) {
            IParticipant(_winner.owner).onWin{
                value: Gas.ON_WIN_VALUE,
                flag: MsgFlag.SENDER_PAYS_FEES,
                bounce: false
            }(_winner.price, _winner.amount);
        }
        emit Finish(success, _winner);
        IAuctionRoot(_root).onFinish{
            value: 0,
            flag: MsgFlag.ALL_NOT_RESERVED,
            bounce: false
        }(success, _winner);
    }

    /***********
     * PRIVATE *
     ***********/

    function _update() private returns (bool) {
        if (_phase == Phase.OPEN && now >= _confirmTime) {
            if (_bidsCount > 0) {
                _phase = Phase.CONFIRM;
            } else {
                _sendFinish();
                return false;
            }
        }
        if (_phase == Phase.CONFIRM && now >= _finishTime) {
            _sendFinish();
            return false;
        }
        return true;
    }

    function _updateResults(BidData data) private {
        if (data.price > _first.price) {
            if (_first.owner.value != 0) {
                _returnBid(_first);
                _second = _first;
            }
            _first = data;
        } else if (data.price > _second.price) {
            _returnBid(data);
            _second = data;
        } else {
            _returnBid(data);
        }
        // if all bids are confirmed
        if (_confirmBidsCount == _bidsCount) {
            _sendFinish();
        }
    }

    function _sendFinish() private {
        _phase = Phase.FINISH;
        IAuction(this).finish{value: 0, flag: MsgFlag.ALL_NOT_RESERVED, bounce: false}();
    }

    function _returnBid(BidData data) private pure {
        data.owner.transfer({value: data.value, flag: MsgFlag.SENDER_PAYS_FEES, bounce: false});
    }

    function _bidAddress(uint256 hash) private view returns (address) {
        TvmCell stateInit = _buildBidStateInit(hash);
        return calcAddress(stateInit);
    }

    function _buildBidStateInit(uint256 hash) private view returns (TvmCell) {
        return tvm.buildStateInit({
            contr: Bid,
            varInit: {
                _auction: address(this),
                _hash: hash
            },
            code: _bidCode
        });
    }

}
