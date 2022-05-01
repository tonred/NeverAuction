pragma ton-solidity >= 0.57.3;

pragma AbiHeader time;
pragma AbiHeader expire;
pragma AbiHeader pubkey;

import "DeAuction.sol";


contract DeAuctionECC is DeAuction {

    uint32 public _neverID;
    address public _electorVault;

    function _init(TvmCell details) internal override {
        (_neverID, _electorVault) = abi.decode(details, (uint32, address));
    }

    function onAcceptTokensTransfer(uint128 amount) public {
        require(msg.sender == _electorVault && _electorVault.value != 0, ErrorCodes.IS_NOT_ELECTOR);
        _onNeverTransfer(amount);
    }

    function _sendNever(address receiver, uint128 value) internal override {
        ExtraCurrencyCollection currencies;
        currencies[_neverID] = value;
        receiver.transfer({
            value: Gas.TRANSFER_VALUE,
            flag: MsgFlag.SENDER_PAYS_FEES,
            bounce: false,
            currencies: currencies
        });
    }

    function buildInitDetails(uint32 neverID, address electorVault) public pure returns (TvmCell details) {
        return abi.encode(neverID, electorVault);
    }

}
