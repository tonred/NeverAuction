pragma ton-solidity >= 0.57.3;

import "ton-eth-bridge-token-contracts/contracts/TokenWalletUpgradeable.sol";


contract TestNeverWallet is TokenWalletUpgradeable {

    fallback() external {}

}
