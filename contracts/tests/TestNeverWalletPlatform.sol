pragma ton-solidity >= 0.57.3;

import "ton-eth-bridge-token-contracts/contracts/TokenWalletPlatform.sol";


contract TestNeverWalletPlatform is TokenWalletPlatform {

    constructor(
        TvmCell walletCode,
        uint32 walletVersion,
        address sender,
        address remainingGasTo
    ) public TokenWalletPlatform(
        walletCode,
        walletVersion,
        sender,
        remainingGasTo
    ) {}

}
