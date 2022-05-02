pragma ton-solidity >= 0.57.3;

import "../../structures/AuctionConfig.sol";
import "../../structures/BidData.sol";
import "../../structures/DeAuctionConfig.sol";


interface IAuctionRoot {
    function expectedAuction(uint64 nonce) external view responsible returns (address auction);
    function expectedDeParticipant(address owner) external view responsible returns (address deParticipant);
    function expectedDeAuction(uint64 nonce) external view responsible returns (address deAuction);
    function currentAuction() external view responsible returns (optional(address) auction);

    function setCodes(TvmCell platformCode, TvmCell auctionCode, TvmCell deAuctionCode, TvmCell deParticipantCode) external;
    function changeElector(address elector) external;
    function changeAuctionConfig(AuctionConfig auctionConfig) external;
    function changeDeAuctionGlobalConfig(DeAuctionGlobalConfig deAuctionGlobalConfig) external;
    function createAuction(uint128 minLotSize, uint128 quotingPrice) external;
    function createDeParticipant() external;
    function createDeAuction(address owner, DeAuctionInitConfig initConfig) external;
    function onFinish(bool success, BidData winner) external;
}
