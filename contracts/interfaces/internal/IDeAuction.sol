pragma ton-solidity >= 0.57.3;

import "../external/IParticipant.sol";
import "../../structures/AuctionDetails.sol";
import "../../structures/BidData.sol";
import "../../structures/Phase.sol";
import "../../structures/PriceRange.sol";


interface IDeAuction is IParticipant {
    function onGetDetails(AuctionDetails details) external;
    function stake(address owner, uint128 value, optional(uint256) priceHash) external;
    function removeStake(address owner, uint128 value) external;
    function confirmPrice(address owner, uint128 price, uint128 value) external;
    function finishSubVoting() external;
    function allowedPrice() external view returns (PriceRange allowed);
    function calcBidHash(uint128 price, uint256 salt) external view returns (uint256 hash);
    function makeBid(uint256 hash) external view;
    function onMakeBid() external override;
    function confirmBid(uint128 price, uint256 salt) external;
    function onConfirmBid() external override;
    function onWin(uint128 price, uint128 amount) external override;
    function pingAuctionFinish() external view;
    function onPingAuctionFinish(Phase before, Phase next) external view;
    function onGetWinner(BidData winner) external;
    function checkAggregator() external view returns (bool isFair);
    function slash() external;
    function claim(address owner, uint128 value) external;
}
