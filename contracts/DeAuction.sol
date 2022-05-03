pragma ton-solidity >= 0.57.3;

pragma AbiHeader time;
pragma AbiHeader expire;
pragma AbiHeader pubkey;

import "./interfaces/external/IAggregator.sol";
import "./interfaces/internal/IAuction.sol";
import "./interfaces/internal/IDeAuction.sol";
import "./interfaces/internal/IDeParticipant.sol";
import "./platform/PlatformUtils.sol";
import "./utils/Constants.sol";
import "./utils/ErrorCodes.sol";
import "./utils/Gas.sol";
import "./utils/HashUtils.sol";
import "./utils/TransferUtils.sol";


abstract contract DeAuction is IDeAuction, PlatformUtils, HashUtils, TransferUtils {
    // todo flow describe
    // todo docstrings
    event Stake(address owner, uint128 value);
    event RemoveStake(address owner, uint128 value);
    event ConfirmPrice(address owner, uint128 price);
    event FinishSubVoting();
    event MakeBid();
    event ConfirmBid();
    event Win(uint128 price, uint128 amount);
    event Lose();
    event Distribution();
    event Slashed();
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

    DeAuctionGlobalConfig public _globalConfig;
    uint32 public _subConfirmTime;
    uint32 public _makeBidTime;

    DePhase public _phase;
    AuctionDetails public _auctionDetails;
    uint128 public _totalStake;

    uint256 _avgTotal;
    uint128 _avgStake;
    uint128 _avgPrice;

    uint128 public _everValue;
    uint128 public _neverValue;
    uint128 public _aggregatorReward;


    modifier onlyAuction() {
        require(msg.sender == _auction, ErrorCodes.IS_NOT_AUCTION);
        _;
    }

    modifier doUpdate() {
        _update();
        _;
    }

    modifier inPhase(DePhase phase) {
        require(_phase == phase, ErrorCodes.WRONG_PHASE);
        _;
    }

    modifier onlyAggregator() {
        require(msg.sender == _aggregator, ErrorCodes.IS_NOT_AGGREGATOR);
        _;
    }

    modifier onlyDeParticipant(address owner) {
        address deParticipant = _deParticipantAddress(_root, owner);
        require(msg.sender == deParticipant, ErrorCodes.IS_NOT_DE_PARTICIPANT);
        _;
    }


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
        (DeAuctionInitConfig initConfig, DeAuctionGlobalConfig globalConfig) = config.unpack();
        (_description, _prices, _deviation, _aggregatorFee, _aggregator, _aggregatorStake) = initConfig.unpack();
        _totalStake = _aggregatorStake;
        _globalConfig = globalConfig;

        _phase = DePhase.INITIALIZING;
        _init(_globalConfig.initDetails);
        address aggregatorDeParticipant = _deParticipantAddress(_root, _aggregator);
        IDeParticipant(aggregatorDeParticipant).onDeAuctionInit{
            value: Gas.DE_AUCTION_ACTION_VALUE,
            flag: MsgFlag.SENDER_PAYS_FEES,
            bounce: false
        }(_nonce, _aggregatorStake);
        IAuction(_auction).getDetails{
            value: 0,
            flag: MsgFlag.ALL_NOT_RESERVED,
            bounce: false,
            callback: onGetDetails
        }();
    }

    function _init(TvmCell details) internal virtual;

    function onGetDetails(AuctionDetails details) public override onlyAuction inPhase(DePhase.INITIALIZING) {
        _auctionDetails = details;
        bool isOpenEnough = now + _globalConfig.subOpenDuration <= details.deBidTime;
        bool isDeBidEnough = _globalConfig.subConfirmDuration + _globalConfig.makeBidDuration <= details.confirmTime - details.deBidTime;
        _subConfirmTime = details.deBidTime;
        _makeBidTime = _subConfirmTime + _globalConfig.subConfirmDuration;
        if (!isOpenEnough || !isDeBidEnough || details.quotingPrice > _prices.min) {
            _phase = DePhase.LOSE;
            // dont return stake here in order to prevent double spending if aggregator call `claim` in parallel tx
        } else {
            _phase = DePhase.SUB_OPEN;
        }
    }


    function getDetails() public view responsible override returns (address root, address auction, DeAuctionConfig details) {
        DeAuctionInitConfig initDetails = DeAuctionInitConfig(_description, _prices, _deviation, _aggregatorFee, _aggregator, _aggregatorStake);
        details = DeAuctionConfig(initDetails, _globalConfig);
        return {value: 0, flag: MsgFlag.REMAINING_GAS, bounce: false} (_root, _auction, details);
    }

    function getStakes() public view responsible override returns (uint128 total, uint128 aggregator) {
        return {value: 0, flag: MsgFlag.REMAINING_GAS, bounce: false} (_totalStake, _aggregatorStake);
    }

    function getTimes() public view responsible override returns (uint32 subConfirmTime, uint32 makeBidTime) {
        return {value: 0, flag: MsgFlag.REMAINING_GAS, bounce: false} (_subConfirmTime, _makeBidTime);
    }

    function getPhase() public view responsible override returns (DePhase phase) {
        return {value: 0, flag: MsgFlag.REMAINING_GAS, bounce: false} _phase;
    }

    function getDistribution() public view responsible override returns (uint128 everValue, uint128 neverValue, uint128 aggregatorReward) {
        return {value: 0, flag: MsgFlag.REMAINING_GAS, bounce: false} (_everValue, _neverValue, _aggregatorReward);
    }


    function stake(address owner, uint128 value, optional(uint256) priceHash) public override onlyDeParticipant(owner) doUpdate {
        bool success = false;
        if (_phase == DePhase.SUB_OPEN) {
            emit Stake(owner, value);
            _totalStake += value;
            success = true;
            if (owner == _aggregator) {
                _aggregatorStake += value;
            }
        }
        uint128 reserve = address(this).balance - msg.value + (success ? value : 0);
        tvm.rawReserve(reserve, 0);
        IDeParticipant(msg.sender).onStake{
            value: 0,
            flag: MsgFlag.ALL_NOT_RESERVED,
            bounce: false
        }(_nonce, value, priceHash, success);
    }

    function removeStake(address owner, uint128 value) public override onlyDeParticipant(owner) doUpdate {
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

    function confirmPrice(address owner, uint128 price, uint128 value) public override onlyDeParticipant(owner) doUpdate {
        bool success = false;
        if (_phase == DePhase.SUB_CONFIRM && _isInRange(price, _prices)) {
            emit ConfirmPrice(owner, price);
            _avgTotal += uint256(price) * value;
            _avgStake += value;
            success = true;
        }
        IDeParticipant(msg.sender).onConfirmPrice{
            value: 0,
            flag: MsgFlag.REMAINING_GAS,
            bounce: false
        }(_nonce, success);
    }

    function finishSubVoting() public override doUpdate inPhase(DePhase.SUB_FINISH) cashBack {
        uint128 minStake = _auctionDetails.minLotSize * _prices.max;
        if (_totalStake < minStake) {
            // not enough stake to bid for all price range
            _phase = DePhase.LOSE;
        } else {
            _phase = DePhase.WAITING_BID;
            if (_avgStake == 0) {
                _avgPrice = uint128((uint256(_prices.min) + _prices.max) / 2);
            } else {
                _avgPrice = uint128(_avgTotal / _avgStake);
            }
        }
        emit FinishSubVoting();
    }

    function allowedPrice() public view override returns (PriceRange allowed) {
        uint128 delta = math.muldiv(_avgPrice, _deviation, Constants.PERCENT_DENOMINATOR);
        uint128 min = math.max(_prices.min, _avgPrice - delta);
        uint128 max = math.min(_prices.max, _avgPrice + delta);
        return PriceRange(min, max);
    }

    /*
    Calculates hash of bid that aggregator make in main auction
    Can be used off-chain before `makeBid` and `removeBid` functions
    @param price    Bid price (in `allowedPrice()` range)
    @param salt     Random 256-bit value (please use really random number)
    @return         256-bit hash
    */
    function calcBidHash(uint128 price, uint256 salt) public view override returns (uint256 hash) {
        PriceRange allowed = allowedPrice();
        require(_isInRange(price, allowed), ErrorCodes.PRICE_OUT_OF_RANGE);
        uint128 amount = _totalStake / price;
        return _calcBidHash(price, amount, address(this), salt);
    }

    function makeBid(uint256 hash) public view override onlyAggregator inPhase(DePhase.WAITING_BID) cashBack {
        IAuction(_auction).makeDeBid{
            value: _auctionDetails.deposit + Gas.DE_AUCTION_ACTION_VALUE,
            flag: MsgFlag.SENDER_PAYS_FEES,
            bounce: true
        }(_nonce, hash);
    }

    function onMakeBid() public override onlyAuction {
        _phase = DePhase.BID_MADE;
        emit MakeBid();
        IAggregator(_aggregator).onMakeBid{value: 0, flag: MsgFlag.REMAINING_GAS, bounce: false}();
    }

    // is never called
    function onRemoveBid() public override onlyAuction { revert(); }

    function confirmBid(uint128 price, uint256 salt) public override onlyAggregator inPhase(DePhase.BID_MADE) {
        // todo fix amount to fit NEVER decimals
        PriceRange allowed = allowedPrice();
        require(_isInRange(price, allowed), ErrorCodes.PRICE_OUT_OF_RANGE);
        uint128 amount = _totalStake / price;
        uint128 value = price * amount;
        tvm.rawReserve(address(this).balance - msg.value - value, 2);
        IAuction(_auction).confirmBid{
            value: value + Gas.DE_AUCTION_ACTION_VALUE,
            flag: MsgFlag.SENDER_PAYS_FEES,
            bounce: true
        }(price, amount, salt);
        msg.sender.transfer({value: 0, flag: MsgFlag.ALL_NOT_RESERVED, bounce: false});
    }

    function onConfirmBid() public override onlyAuction {
        _phase = DePhase.BID_CONFIRMED;
        emit ConfirmBid();
        IAggregator(_aggregator).onConfirmBid{value: 0, flag: MsgFlag.REMAINING_GAS, bounce: false}();
    }

    function onWin(uint128 price, uint128 amount) public override onlyAuction {
        _phase = DePhase.WIN;
        _everValue = _totalStake - price * amount;
        emit Win(price, amount);
        IAggregator(_aggregator).onWin{value: 0, flag: MsgFlag.REMAINING_GAS, bounce: false}(price, amount);
    }

    function pingAuctionFinish() public view override inPhase(DePhase.BID_CONFIRMED) {
        IAuction(_auction).getPhase{
            value: 0,
            flag: MsgFlag.REMAINING_GAS,
            bounce: false,
            callback: onPingAuctionFinish
        }();
    }

    function onPingAuctionFinish(Phase phase) public view override onlyAuction inPhase(DePhase.BID_CONFIRMED) {
        _reserve();
        if (phase == Phase.FINISH) {
            IAuction(_auction).finish{
                value: Gas.DE_AUCTION_PING_FINISH_VALUE,
                flag: MsgFlag.SENDER_PAYS_FEES,
                bounce: false
            }();
        }
        if (phase == Phase.FINISH || phase == Phase.DONE) {
            IAuction(_auction).getWinner{
                value: 0,
                flag: MsgFlag.ALL_NOT_RESERVED,
                bounce: false,
                callback: onGetWinner
            }();
        }
    }

    function onGetWinner(BidData winner) public override onlyAuction inPhase(DePhase.BID_CONFIRMED) {
        if (winner.owner != address(this)) {
            emit Lose();
            _phase = DePhase.LOSE;
        }
        // onWin case is called automatically by Auction
    }

    function _onNeverTransfer(uint128 value) internal inPhase(DePhase.WIN) {
        _phase = DePhase.DISTRIBUTION;
        _aggregatorReward = math.muldiv(value, _aggregatorFee, Constants.PERCENT_DENOMINATOR);
        _neverValue = value - _aggregatorReward;
        emit Distribution();
    }

    function checkAggregator() public view override returns (bool isFair) {
        if (now >= _auctionDetails.confirmTime && _phase < DePhase.BID_MADE) {
            // aggregator forgot to make bid
            return false;
        }
        if (now >= _auctionDetails.finishTime && _phase < DePhase.BID_CONFIRMED) {
            // aggregator forgot to confirm bid
            return false;
        }
        return true;
    }

    function slash() public override cashBack {
        bool isFair = checkAggregator();
        require(!isFair, ErrorCodes.AGGREGATOR_IS_FAIR);
        _slash();
    }

    function _slash() private {
        _phase = DePhase.SLASHED;
        _totalStake -= _aggregatorStake;
        emit Slashed();
    }

    function claim(address owner, uint128 value) public override onlyDeParticipant(owner) {
        bool success = true;
        uint128 everValue = 0;
        uint128 neverValue = 0;
        bool isAggregator = owner == _aggregator;
        if (_phase == DePhase.DISTRIBUTION) {
            everValue = math.muldiv(_everValue, value, _totalStake);
            neverValue = math.muldiv(_neverValue, value, _totalStake);
            if (isAggregator) {
                neverValue += _aggregatorReward;
            }
        } else if (_phase == DePhase.LOSE) {
            everValue = value;
        } else if (_phase == DePhase.SLASHED) {
            if (!isAggregator) {
                everValue = value + math.muldiv(_aggregatorStake, value, _totalStake);
            }
        } else {
            success = false;
        }

        if (success) {
            emit Claim(owner, everValue, neverValue);
            if (neverValue > 0) {
                _sendNever(owner, neverValue);
            }
        }
        IDeParticipant(msg.sender).onClaim{
            value: everValue,
            flag: MsgFlag.REMAINING_GAS,
            bounce: false
        }(_nonce, success);
    }

    function _sendNever(address receiver, uint128 value) internal virtual;

    function _update() private {
        if (_phase == DePhase.SUB_OPEN && now >= _subConfirmTime) {
            _phase = DePhase.SUB_CONFIRM;
        }
        if (_phase == DePhase.SUB_CONFIRM && now >= _makeBidTime) {
            _phase = DePhase.SUB_FINISH;
        }
    }

    function _isInRange(uint128 price, PriceRange range) private pure returns (bool) {
        return price >= range.min && price <= range.max;
    }


    onBounce(TvmSlice body) external view {
        uint32 functionId = body.decode(uint32);
        if (functionId == tvm.functionId(IAuction.makeBid)) {
            _aggregator.transfer({value: 0, flag: MsgFlag.REMAINING_GAS, bounce: false});
        } else if (functionId == tvm.functionId(IAuction.confirmBid)) {
            // do nothing, keep value in DeAuction
        }
    }

}
