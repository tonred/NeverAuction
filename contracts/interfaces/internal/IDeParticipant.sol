pragma ton-solidity >= 0.57.3;

import "../../structures/PriceRange.sol";


interface IDeParticipant {
    // todo order
    function createDeAuction(
        string description,
        PriceRange prices,
        uint128 deviation,
        uint128 fee,
        uint128 value
    ) external;
    function onDeAuctionInit(uint64 nonce, uint128 value) external;
    function stake(address deAuction, uint128 value, optional(uint256) priceHash) external;
    function onStake(uint64 nonce, uint128 value, optional(uint256) priceHash, bool success) external;
    function removeStake(address deAuction, uint128 value) external;
    function onRemoveStake(uint64 nonce, uint128 value, bool success) external;
    function confirmPrice(address deAuction, uint128 price, uint256 salt) external;
    function onConfirmPrice(uint64 nonce, bool success) external;
    function claim(address deAuction) external;
    function onClaim(uint64 nonce, bool success) external;
    function calcPriceHash(uint128 price, uint256 salt) external returns (uint256);
}
