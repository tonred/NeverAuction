pragma ton-solidity >= 0.57.3;

import "../../structures/AuctionDetails.sol";
import "../../structures/BidData.sol";
import "../../structures/Phase.sol";


interface IAuction {
    function getDetails() external view responsible returns (AuctionDetails details);
    function getPhase() external view responsible returns (Phase phase);
    function getWinner() external view responsible returns (BidData winner);

    function updateAndGetPhase() external responsible returns (Phase before, Phase next);
    function update() external;

    function makeBid(uint256 hash) external;
    function makeDeBid(uint64 nonce, uint256 hash) external;
    function removeBid(uint256 hash) external view;
    function onRemoveBid(uint256 hash, address owner) external;
    function confirmBid(uint128 price, uint128 amount, uint256 salt) external view;
    function onConfirmBid(uint256 hash, BidData data, uint128 msgValue) external;
    function calcBidHash(uint128 price, uint128 amount, address owner, uint256 salt) external view returns (uint256 hash);
    function finish() external;
}
