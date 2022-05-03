pragma ton-solidity >= 0.57.3;

pragma AbiHeader time;
pragma AbiHeader expire;
pragma AbiHeader pubkey;

import "./interfaces/external/IDeOwner.sol";
import "./interfaces/internal/IAuctionRoot.sol";
import "./interfaces/internal/IDeAuction.sol";
import "./interfaces/internal/IDeParticipant.sol";
import "./platform/PlatformUtils.sol";
import "./utils/ErrorCodes.sol";
import "./utils/Gas.sol";
import "./utils/TransferUtils.sol";


contract DeParticipant is IDeParticipant, PlatformUtils, TransferUtils {
    event NewDeAuction(address deAuction, uint128 value);
    event Stake(address deAuction, uint128 value, optional(uint256) priceHash);
    event RemoveStake(address deAuction, uint128 value);
    event ConfirmPrice(address deAuction);
    event Claim(address deAuction);

    address public _root;
    address public _owner;

    bool public _lock;
    mapping(address => uint128) public _stakes;
    mapping(address => optional(uint256)) public _hashes;


    modifier onlyOwner() {
        require(msg.sender == _owner, ErrorCodes.IS_NOT_OWNER);
        _;
    }

    modifier onlyDeAuction(uint64 nonce) {
        address deAuction = _deAuctionAddress(_root, nonce);
        require(msg.sender == deAuction, ErrorCodes.IS_NOT_DE_AUCTION);
        _;
    }

    modifier withLock() {
        require(_lock == false, ErrorCodes.LOCKED);
        _lock = true;
        _;
    }

    modifier unlock() {
        _lock = false;
        _;
    }


    function onCodeUpgrade(TvmCell input) private {
        tvm.resetStorage();
        TvmSlice slice = input.toSlice();
        (_root, /*type*/, /*remainingGasTo*/) = slice.decode(address, uint8, address);
        _platformCode = slice.loadRef();

        TvmCell initialData = slice.loadRef();
        _owner = abi.decode(initialData, address);
        /*TvmCell initialParams = */slice.loadRef();
    }


    function getDetails() public view responsible override returns (address root, address owner) {
        return {value: 0, flag: MsgFlag.REMAINING_GAS, bounce: false} (_root, _owner);
    }

    function getDeAuctionData(address deAuction) public view responsible override returns (bool exists, uint128 stake, optional(uint256) hash) {
        exists = _stakes.exists(deAuction);
        return {value: 0, flag: MsgFlag.REMAINING_GAS, bounce: false} (exists, _stakes[deAuction], _hashes[deAuction]);
    }


    function createDeAuction(
        string description,
        PriceRange prices,
        uint128 deviation,
        uint128 fee,
        uint128 value
    ) public view override onlyOwner cashBack {
        require(value > 0, ErrorCodes.LOW_VALUE);
        DeAuctionInitConfig initConfig = DeAuctionInitConfig(description, prices, deviation, fee, _owner, value);
        IAuctionRoot(_root).createDeAuction{
            value: value + Gas.DE_AUCTION_INIT_VALUE,
            flag: MsgFlag.SENDER_PAYS_FEES,
            bounce: false
        }(_owner, initConfig);
    }

    function onDeAuctionInit(uint64 nonce, uint128 value) public override onlyDeAuction(nonce) {
        _stakes[msg.sender] += value;
        emit NewDeAuction(msg.sender, value);
        IDeOwner(_owner).onDeAuctionInit{value: 0, flag: MsgFlag.REMAINING_GAS, bounce: false}(msg.sender, value);
    }

    function stake(address deAuction, uint128 value, optional(uint256) priceHash) public view override onlyOwner withLock cashBack {
        require(value > 0, ErrorCodes.LOW_VALUE);
        IDeAuction(deAuction).stake{
            value: value + Gas.DE_PARTICIPANT_ACTION_VALUE,
            flag: MsgFlag.SENDER_PAYS_FEES,
            bounce: false
        }(_owner, value, priceHash);
    }

    function onStake(uint64 nonce, uint128 value, optional(uint256) priceHash, bool success) public override onlyDeAuction(nonce) unlock {
        if (success) {
            emit Stake(msg.sender, value, priceHash);
            _stakes[msg.sender] += value;
            if (priceHash.hasValue()) {
                _hashes[msg.sender] = priceHash.get();
            }
        }
        IDeOwner(_owner).onStake{value: 0, flag: MsgFlag.REMAINING_GAS, bounce: false}(value, priceHash, success);
    }

    function removeStake(address deAuction, uint128 value) public view override onlyOwner withLock cashBack {
        require(value > 0, ErrorCodes.LOW_VALUE);
        require(_stakes[deAuction] >= value, ErrorCodes.VALUE_MORE_THAN_STAKE);
        IDeAuction(deAuction).removeStake{
            value: Gas.DE_PARTICIPANT_ACTION_VALUE,
            flag: MsgFlag.SENDER_PAYS_FEES,
            bounce: false
        }(_owner, value);
    }

    function onRemoveStake(uint64 nonce, uint128 value, bool success) public override onlyDeAuction(nonce) unlock {
        bool fully = false;
        if (success) {
            emit RemoveStake(msg.sender, value);
            _stakes[msg.sender] -= value;
            if (_stakes[msg.sender] == 0) {
                _cleanDeAuctionData(msg.sender);
                fully = true;
            }
        }
        IDeOwner(_owner).onRemoveStake{value: 0, flag: MsgFlag.REMAINING_GAS, bounce: false}(value, success, fully);
    }

    function confirmPrice(address deAuction, uint128 price, uint256 salt) public override onlyOwner withLock cashBack {
        optional(uint256) hash = _hashes[deAuction];
        uint256 expectedHash = calcPriceHash(price, salt);
        require(hash.hasValue() && hash.get() == expectedHash, ErrorCodes.WRONG_HASH);
        IDeAuction(deAuction).confirmPrice{
            value: Gas.DE_PARTICIPANT_ACTION_VALUE,
            flag: MsgFlag.SENDER_PAYS_FEES,
            bounce: false
        }(_owner, price, _stakes[deAuction]);
    }

    function onConfirmPrice(uint64 nonce, bool success) public override onlyDeAuction(nonce) unlock {
        if (success) {
            emit ConfirmPrice(msg.sender);
            delete _hashes[msg.sender];
        }
        IDeOwner(_owner).onConfirmPrice{value: 0, flag: MsgFlag.REMAINING_GAS, bounce: false}(success);
    }

    function claim(address deAuction) public view override onlyOwner withLock cashBack {
        require(_stakes[deAuction] > 0, ErrorCodes.NO_STAKE);
        IDeAuction(deAuction).claim{
            value: Gas.DE_PARTICIPANT_ACTION_VALUE,
            flag: MsgFlag.SENDER_PAYS_FEES,
            bounce: false
        }(_owner, _stakes[deAuction]);
    }

    function onClaim(uint64 nonce, bool success) public override onlyDeAuction(nonce) unlock {
        if (success) {
            emit Claim(msg.sender);
            _cleanDeAuctionData(msg.sender);
        }
        IDeOwner(_owner).onClaim{value: 0, flag: MsgFlag.REMAINING_GAS, bounce: false}(success);
    }

    function calcPriceHash(uint128 price, uint256 salt) public view override returns (uint256 hash) {
        TvmCell data = abi.encode(price, _owner, salt);
        return tvm.hash(data);
    }

    function _cleanDeAuctionData(address deAuction) private inline {
        delete _stakes[deAuction];
        delete _hashes[deAuction];
    }

}
