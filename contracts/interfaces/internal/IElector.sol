pragma ton-solidity >= 0.57.3;


interface IElector {
    function onAuctionFinish(bool success, address winner, uint128 price, uint128 amount) external;
}
