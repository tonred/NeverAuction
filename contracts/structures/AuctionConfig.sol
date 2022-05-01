pragma ton-solidity >= 0.57.3;


struct AuctionConfig {
    uint128 fee;  // must be more than DEPLOY_BID_VALUE
    uint128 deposit;  // must be more than fee
    uint32 openDuration;
    uint32 deBidDuration;
    uint32 confirmDuration;
    TvmCell bidCode;
}
