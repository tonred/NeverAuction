pragma ton-solidity >= 0.57.3;

import "../../structures/AuctionDetails.sol";
import "../../structures/BidData.sol";
import "../../structures/Phase.sol";


interface IElector {
    function onAuctionFinish(bool success, address winner, uint128 price, uint128 amount) external;
}
