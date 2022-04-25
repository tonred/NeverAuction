pragma ton-solidity >= 0.57.3;

import "./PriceRange.sol";


struct DeAuctionConfig {
    string description;
    PriceRange prices;
    uint128 deviation;
    uint128 aggregatorFee;
    address aggregator;
    uint128 aggregatorStake;
}
