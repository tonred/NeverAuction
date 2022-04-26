pragma ton-solidity >= 0.57.3;

pragma AbiHeader time;
pragma AbiHeader expire;
pragma AbiHeader pubkey;

import "./interfaces/external/IAggregator.sol";
import "./interfaces/internal/IAuction.sol";
import "./interfaces/internal/IDeAuction.sol";
import "./interfaces/internal/IDeParticipant.sol";
import "./platform/PlatformUtils.sol";
import "./structures/DeAuctionConfig.sol";
import "./structures/DePhase.sol";
import "./utils/Constants.sol";
import "./utils/ErrorCodes.sol";
import "./utils/Gas.sol";
import "./utils/TransferUtils.sol";


contract DeAuction is IDeAuction, PlatformUtils, TransferUtils {
    // todo flow describe
    // todo docstrings
    event Stake(address owner, uint128 value);
    event RemoveStake(address owner, uint128 value);
    event ConfirmPrice(address owner, uint128 price);
    event Claim(address owner, uint128 everValue, uint128 neverValue);

    address public _root;
    uint64 public _nonce;

    address public _auction;
    string public _description;
    PriceRange public _prices;
    uint128 public _deviation;
    uint128 public _aggregatorFee;
    address public _aggregator;
    uint128 public _aggregatorStake;

    DePhase public _phase;
    AuctionDetails public _details;
    uint128 public _totalStake;

    uint128 _avgPrice;
    uint128 _avgValue;

    uint128 _everValue;
    uint128 _neverValue;
    uint128 _aggregatorReward;


    modifier onlyAuction() {
        require(msg.sender == _auction, ErrorCodes.IS_NOT_AUCTION);
        _;
    }

    modifier inPhase(DePhase phase) {
        require(_phase == phase, 69);
        _;
    }

    modifier onlyAggregator() {
        require(msg.sender == _aggregator, ErrorCodes.IS_NOT_AGGREGATOR);
        _;
    }

    modifier onlyDeParticipant(address owner) {
        address deParticipant = _deParticipantAddress(owner);
        require(msg.sender == deParticipant, ErrorCodes.IS_NOT_DE_PARTICIPANT);
        _;
    }


    // todo docstring
    // todo Platform
    function onCodeUpgrade(TvmCell input) private {
        tvm.resetStorage();
        TvmSlice slice = input.toSlice();
        (_root, /*type*/, /*remainingGasTo*/) = slice.decode(address, uint8, address);
        _platformCode = slice.loadRef();

        TvmCell initialData = slice.loadRef();
        _nonce = abi.decode(initialData, uint64);

        TvmCell initialParams = slice.loadRef();
        DeAuctionConfig config;
        (_auction, config) = abi.decode(initialParams, (address, DeAuctionConfig));
        (_description, _prices, _deviation, _aggregatorFee, _aggregator, _aggregatorStake) = config.unpack();

        _phase = DePhase.INITIALIZING;
        IAuction(_auction).getDetails{
            value: 0,
            flag: MsgFlag.ALL_NOT_RESERVED,
            bounce: false,
            callback: onGetDetails
        }();
    }

    function onGetDetails(AuctionDetails details) public override onlyAuction inPhase(DePhase.INITIALIZING) {
        // todo check if is too late to create deauction (or just wait for finishVoting)
        // todo check that _prices.min >= quotingPrice
        _details = details;
        if (details.confirmTime <= now + 3 days || details.quotingPrice > _prices.min) {  // todo 3 days
            _phase = DePhase.LOSE;
        } else {
            _phase = DePhase.SUB_OPEN;
        }
    }

    function stake(address owner, uint128 value, optional(uint256) priceHash) public override onlyDeParticipant(owner) {
        bool success = false;
        if (_phase == DePhase.SUB_OPEN) {
            emit Stake(owner, value);
            _totalStake += value;
            success = true;
            if (owner == _aggregator) {
                _aggregatorStake += value;
            }
        }
        IDeParticipant(msg.sender).onStake{
            value: 0,
            flag: MsgFlag.REMAINING_GAS,
            bounce: false
        }(_nonce, value, priceHash, success);
    }

    function removeStake(address owner, uint128 value) public override onlyDeParticipant(owner) {
        bool success = false;
        if (_phase == DePhase.SUB_OPEN && owner != _aggregator) {
            emit RemoveStake(owner, value);
            _totalStake -= value;
            success = true;
        }
        IDeParticipant(msg.sender).onRemoveStake{
            value: success ? value : 0,
            flag: MsgFlag.REMAINING_GAS,
            bounce: false
        }(_nonce, value, success);
    }

    function confirmPrice(address owner, uint128 price, uint128 value) public override onlyDeParticipant(owner) {
        bool success = false;
        if (_phase == DePhase.SUB_CONFIRM && _inPriceRange(_prices, price)) {
            emit ConfirmPrice(owner, price);
            _avgPrice = (_avgPrice * _avgValue + price * value) / (_avgValue + value);
            _avgValue += value;
            success = true;
        }
        IDeParticipant(msg.sender).onConfirmPrice{
            value: 0,
            flag: MsgFlag.REMAINING_GAS,
            bounce: false
        }(_nonce, success);
    }

    // todo auto-next phase
    function finishVoting() public override onlyAggregator inPhase(DePhase.SUB_FINISH) cashBack {
        uint128 minByLot = _totalStake / _details.minLotSize;
        if (minByLot > _prices.min) {
            // not enough stake to bid for full price range  // todo discuss
            _phase = DePhase.LOSE;
        } else {
            _phase = DePhase.WAITING_BID;
        }
    }

    function allowedPrice() public override returns (PriceRange allowed) {
        uint128 delta = math.muldiv(_avgValue, _deviation, Constants.PERCENT_DENOMINATOR);
        uint128 min = math.max(_prices.min, _avgPrice - delta);
        uint128 max = math.min(_prices.max, _avgPrice + delta);
        return PriceRange(min, max);
    }

    function _inPriceRange(PriceRange range, uint128 price) private pure returns (bool) {
        return price >= range.min && price <= range.max;
    }

    function makeBid(uint256 hash) public override onlyAggregator inPhase(DePhase.WAITING_BID) cashBack {
//        require(now > _details.openTime && now < _details.confirmationTime, 69);
        IAuction(_auction).makeBid{
            value: _details.deposit + Gas.DE_AUCTION_ACTION_VALUE,
            flag: MsgFlag.SENDER_PAYS_FEES,
            bounce: true  // todo it is possible situation when it is time to close on no bounce and no callback
        }(hash);
    }

    // todo calc bid hash

    function onMakeBid() public override onlyAuction {
        _phase = DePhase.BID_MADE;
        IAggregator(_aggregator).onMakeBid{value: 0, flag: MsgFlag.REMAINING_GAS, bounce: false}();
    }

    function onRemoveBid() public override onlyAuction { revert(); }

    function confirmBid(uint128 price, uint256 salt) public override onlyAggregator inPhase(DePhase.BID_MADE) {
        PriceRange allowed = allowedPrice();
        require(_inPriceRange(allowed, price), 69);
        uint128 amount = _totalStake / price;
        IAuction(_auction).confirmBid{
            value: price * amount + Gas.DE_AUCTION_ACTION_VALUE,
            flag: MsgFlag.SENDER_PAYS_FEES,
            bounce: true  // todo it is possible situation when it is time to close on no bounce and no callback
        }(price, amount, salt);
    }

    function onConfirmBid() public override onlyAuction {
        _phase = DePhase.BID_CONFIRMED;
        IAggregator(_aggregator).onConfirmBid{value: 0, flag: MsgFlag.REMAINING_GAS, bounce: false}();
    }

    function onWin(uint128 price, uint128 amount) public override onlyAuction {
        _phase = DePhase.WIN;
        _everValue = _totalStake - price * amount;
        IAggregator(_aggregator).onWin{value: 0, flag: MsgFlag.REMAINING_GAS, bounce: false}(price, amount);
    }

    function pingAuctionFinish() public override {
        IAuction(_auction).updateAndGetPhase{
            value: 0,
            flag: MsgFlag.REMAINING_GAS,
            bounce: false,
            callback: onPingAuctionFinish
        }();
    }

    function onPingAuctionFinish(Phase /*before*/, Phase next) public override onlyAuction inPhase(DePhase.BID_CONFIRMED) {
        if (next == Phase.FINISH) {
            IAuction(_auction).getWinner{
                value: 0,
                flag: MsgFlag.REMAINING_GAS,
                bounce: false,
                callback: onGetWinner
            }();
        }
    }

    function onGetWinner(BidData winner) public override onlyAuction inPhase(DePhase.BID_CONFIRMED) {
        if (winner.owner != address(this)) {
            _phase = DePhase.LOSE;
        }
        // onWin case is called automatically by Auction
    }

    function onNeverTransfer(uint128 value) public override onlyAuction inPhase(DePhase.WIN) {
        // todo only elector
        _phase = DePhase.DISTRIBUTION;
        _aggregatorReward = math.muldiv(value, _aggregatorFee, Constants.PERCENT_DENOMINATOR);
        _neverValue = value - _aggregatorReward;
    }

    function slash() public override {
        bool isFair = checkAggregator();
        if (!isFair) {
            _slash();
        }
    }

    function _slash() private {
        _phase = DePhase.SLASHED;
    }

    function checkAggregator() public override returns (bool) {
        Phase auctionPhase = auctionPhase();
        if (auctionPhase == Phase.CONFIRM && _phase < DePhase.BID_MADE) {
            // aggregator forgot to make bid
            return false;
        }
        if (auctionPhase == Phase.FINISH && _phase < DePhase.BID_CONFIRMED) {
            // aggregator forgot to confirm bid
            return false;
        }
        return true;
    }

    function claim(address owner, uint128 value) public override onlyDeParticipant(owner) {
        bool success = true;
        uint128 everValue = 0;
        uint128 neverValue = 0;
        if (_phase == DePhase.DISTRIBUTION) {
            everValue = math.muldiv(_everValue, value, _totalStake);
            neverValue = math.muldiv(_neverValue, value, _totalStake);
            if (owner == _aggregator) {
                neverValue += _aggregatorReward;
            }
        } else if (_phase == DePhase.LOSE) {
            everValue = value;
        } else if (_phase == DePhase.SLASHED && msg.sender != _aggregator) {
            everValue = value + math.muldiv(_aggregatorStake, value, _totalStake);
        } else {
            success = false;
        }

        if (success) {
            emit Claim(owner, everValue, neverValue);
            if (neverValue > 0) {
                // todo send never
            }
        }
        IDeParticipant(msg.sender).onClaim{
            value: value,
            flag: MsgFlag.REMAINING_GAS,
            bounce: false
        }(_nonce, success);
    }

    function auctionPhase() public view returns (Phase) {
        require(_phase != DePhase.INITIALIZING, 69);
        return Phase.OPEN;
        // todo
//        if (now < _times.open) {
//            return Phase.WAIT;
//        } else if (now >= _times.open && now < _times.confirmation) {
//            return Phase.OPEN;
//        } else if (now >= _times.confirmation && now < _times.finish) {
//            return Phase.CONFIRM;
//        } else {
//            return Phase.FINISH;
//        }
    }

    onBounce(TvmSlice body) external pure {
        uint32 functionId = body.decode(uint32);
        if (functionId == tvm.functionId(IAuction.makeBid)) {
            // todo wrong phase
        }
    }

}
