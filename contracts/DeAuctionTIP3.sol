pragma ton-solidity >= 0.57.3;

pragma AbiHeader time;
pragma AbiHeader expire;
pragma AbiHeader pubkey;

import "DeAuction.sol";

import "ton-eth-bridge-token-contracts/contracts/interfaces/IAcceptTokensMintCallback.sol";
import "ton-eth-bridge-token-contracts/contracts/interfaces/ITokenRoot.sol";
import "ton-eth-bridge-token-contracts/contracts/interfaces/ITokenWallet.sol";


contract DeAuctionTIP3 is DeAuction, IAcceptTokensMintCallback {

    address public _neverRoot;  // from details
    address public _neverWallet;

    function _init(TvmCell details) internal override {
        _neverRoot = abi.decode(details, address);
        ITokenRoot(_neverRoot).deployWallet{
            value: Gas.DEPLOY_WALLET_VALUE,
            flag: MsgFlag.SENDER_PAYS_FEES,
            bounce: false,
            callback: onWalletDeployed
        }(address(this), Gas.DEPLOY_WALLET_GRAMS);
    }

    function onWalletDeployed(address wallet) public {
        require(msg.sender == _neverRoot && _neverRoot.value != 0, ErrorCodes.IS_NOT_TOKEN_ROOT);
        _neverWallet = wallet;
    }

    function getNeverDetails() public view responsible returns (address neverRoot, address neverWallet) {
        return {value: 0, flag: MsgFlag.REMAINING_GAS, bounce: false} (_neverRoot, _neverWallet);
    }

    function onAcceptTokensMint(
        address /*tokenRoot*/,
        uint128 amount,
        address /*remainingGasTo*/,
        TvmCell /*payload*/
    ) public override inPhase(DePhase.WIN) {
        require(msg.sender == _neverWallet && msg.sender.value != 0, ErrorCodes.IS_NOT_TOKEN_WALLET);
        _onNeverTransfer(amount);
    }

    function _sendNever(address receiver, uint128 value) internal override {
        TvmCell empty;
        ITokenWallet(_neverWallet).transfer{
            value: Gas.TRANSFER_TIP3_VALUE,
            flag: MsgFlag.SENDER_PAYS_FEES,
            bounce: false
        }(
            value,                      // amount
            receiver,                   // recipient
            Gas.DEPLOY_WALLET_GRAMS,    // deployWalletValue
            receiver,                   // remainingGasTo
            false,                      // notify
            empty                       // payload
        );
    }

    function buildInitDetails(address neverRoot) public pure returns (TvmCell details) {
        return abi.encode(neverRoot);
    }

}
