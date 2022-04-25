pragma ton-solidity >= 0.57.3;

import "../../structures/DeAuctionErrorReason.sol";
import "IParticipant.sol";


interface IAggregator is IParticipant {
    function onCreateDeAuctionException(DeAuctionErrorReason error) external;
}
