pragma ton-solidity >= 0.57.3;


abstract contract HashUtils {

    function _calcBidHash(uint128 price, uint128 amount, address sender, uint256 salt) internal pure inline returns (uint256) {
        TvmCell data = abi.encode(price, amount, sender, salt);
        return tvm.hash(data);
    }

}
