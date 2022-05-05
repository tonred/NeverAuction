pragma ton-solidity >= 0.57.3;


library Constants {
    uint32 constant MAX_STRING_LENGTH = 1024;
    uint128 constant PERCENT_DENOMINATOR = 100_000;
    uint128 constant MIN_LOT_SIZE = 0.1 ton;  // todo set bigger value in production (maybe 1_000_000)
}
