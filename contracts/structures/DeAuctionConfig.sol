pragma ton-solidity >= 0.57.3;

import "./PriceRange.sol";


struct DeAuctionConfig {
    DeAuctionInitConfig init;
    DeAuctionGlobalConfig global;
}

struct DeAuctionInitConfig {
    string description;
    PriceRange prices;
    uint128 deviation;
    uint128 aggregatorFee;
    address aggregator;
    uint128 aggregatorStake;
}

struct DeAuctionGlobalConfig {
    uint32 subOpenDuration;
    uint32 subConfirmDuration;
    uint32 makeBidDuration;
    TvmCell initDetails;
}
