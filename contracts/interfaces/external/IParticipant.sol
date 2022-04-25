pragma ton-solidity >= 0.57.3;


interface IParticipant {
    function onMakeBid() external;
    function onRemoveBid() external;
    function onConfirmBid() external;
    function onWin(uint128 price, uint128 amount) external;
}
