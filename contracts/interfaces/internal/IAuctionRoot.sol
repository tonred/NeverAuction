pragma ton-solidity >= 0.57.3;

import "../../structures/AuctionConfig.sol";
import "../../structures/BidData.sol";
import "../../structures/DeAuctionConfig.sol";


interface IAuctionRoot {
    function expectedDeParticipant(address owner) external view responsible returns (address deParticipant);
    function currentAuction() external responsible returns (optional(address) auction);

    function changeConfiguration(AuctionConfig config) external;
    function createAuction(uint128 minLotSize, uint128 quotingPrice) external;
    function createDeAuction(address owner, DeAuctionConfig config) external;
    function onFinish(bool success, BidData winner) external;
}
