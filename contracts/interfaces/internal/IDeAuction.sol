pragma ton-solidity >= 0.57.3;

import "../external/IParticipant.sol";
import "../../structures/AuctionDetails.sol";
import "../../structures/BidData.sol";
import "../../structures/Phase.sol";
import "../../structures/PriceRange.sol";


interface IDeAuction is IParticipant {
    // todo sort by tile
    function onGetDetails(AuctionDetails details) external;
    function stake(address owner, uint128 value, optional(uint256) priceHash) external;
    function removeStake(address owner, uint128 value) external;
    function confirmPrice(address owner, uint128 price, uint128 value) external;
    function finishVoting() external;
    function allowedPrice() external returns (PriceRange allowed);
    function makeBid(uint256 hash) external;
    function onMakeBid() external override;
    function confirmBid(uint128 price, uint256 salt) external;
    function onConfirmBid() external override;
    function onWin(uint128 price, uint128 amount) external override;
    function pingAuctionFinish() external;
    function onPingAuctionFinish(Phase before, Phase next) external;
    function onGetWinner(BidData winner) external;
    function onNeverTransfer(uint128 value) external;
    function slash() external;
    function checkAggregator() external returns (bool);
    function claim(address owner, uint128 value) external;
//    function auctionPhase() external returns (Phase); // todo

}
