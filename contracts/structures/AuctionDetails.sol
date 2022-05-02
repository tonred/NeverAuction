pragma ton-solidity >= 0.57.3;


struct AuctionDetails {
    address root;
    uint128 fee;
    uint128 deposit;
    uint32 deBidTime;
    uint32 confirmTime;
    uint32 finishTime;
    uint128 minLotSize;
    uint128 quotingPrice;
}
