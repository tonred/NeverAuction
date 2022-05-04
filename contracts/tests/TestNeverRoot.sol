pragma ton-solidity >= 0.57.3;

import "ton-eth-bridge-token-contracts/contracts/TokenRootUpgradeable.sol";


contract TestNeverRoot is TokenRootUpgradeable {

    constructor(
        address initialSupplyTo,
        uint128 initialSupply,
        uint128 deployWalletValue,
        bool mintDisabled,
        bool burnByRootDisabled,
        bool burnPaused,
        address remainingGasTo,
        address owner
    ) public TokenRootUpgradeable(
        initialSupplyTo,
        initialSupply,
        deployWalletValue,
        mintDisabled,
        burnByRootDisabled,
        burnPaused,
        remainingGasTo
    ) {
        rootOwner_ = owner;
    }

}
