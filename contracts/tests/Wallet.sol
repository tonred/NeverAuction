pragma ton-solidity >= 0.57.3;

import "@broxus/contracts/contracts/wallets/Account.sol";


contract Wallet is Account {

    fallback() external {}

}
