pragma ton-solidity >= 0.57.3;


struct AuctionConfig {
    uint128 fee;
    uint128 deposit;
    uint32 openDuration;
    uint32 confirmDuration;
    TvmCell bidCode;
}
