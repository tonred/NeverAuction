pragma ton-solidity >= 0.57.3;

import 'Constants.sol';


library Converter {
    uint8 constant DECIMALS = 9;  // same for ever and never
    uint128 constant MULTIPLIER = uint128(10) ** DECIMALS;

    function toValue(uint128 price, uint128 amount) public returns (uint128) {
        return math.muldiv(price, amount, MULTIPLIER);
    }

    function toAmount(uint128 value, uint128 price) public returns (uint128) {
        return math.muldiv(MULTIPLIER, value, price);
    }
}
