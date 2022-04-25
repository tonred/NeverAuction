pragma ton-solidity >= 0.57.3;

pragma AbiHeader time;
pragma AbiHeader expire;
pragma AbiHeader pubkey;

import "./structures/BidData.sol";
import "./utils/ErrorCodes.sol";

import "@broxus/contracts/contracts/libraries/MsgFlag.sol";


contract Bid {
    address public static _auction;
    uint256 public static _hash;
    address public _owner;

    modifier onlyAuction() {
        require(msg.sender == _auction, ErrorCodes.IS_NOT_AUCTION);
        _;
    }

    constructor(address owner) public onlyAuction {
        _owner = owner;
    }

    function getDetails() public view responsible returns (address, address, uint256) {
        return {value: 0, flag: MsgFlag.REMAINING_GAS, bounce: false} (_auction, _owner, _hash);
    }

    function remove() public view responsible onlyAuction returns (uint256, address) {
        return {value: 0, flag: MsgFlag.ALL_NOT_RESERVED + MsgFlag.DESTROY_IF_ZERO, bounce: false} (_hash, _owner);
    }

    function confirm(BidData data, uint128 msgValue) public view responsible onlyAuction returns (uint256, BidData, uint128) {
        return {value: 0, flag: MsgFlag.ALL_NOT_RESERVED + MsgFlag.DESTROY_IF_ZERO, bounce: false} (_hash, data, msgValue);
    }

}
