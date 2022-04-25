pragma ton-solidity >= 0.57.3;

import "../../structures/DeAuctionErrorReason.sol";
import "IParticipant.sol";


interface IDeOwner {
    function onDeAuctionInit(address deAuction, uint128 value) external;
    function onStake(uint128 value, optional(uint256) priceHash, bool success) external;
    function onRemoveStake(uint128 value, bool success, bool fully) external;
    function onConfirmPrice(bool success) external;
    function onClaim(bool success) external;
}
