pragma ton-solidity >= 0.57.3;

pragma AbiHeader expire;
pragma AbiHeader time;
pragma AbiHeader pubkey;

import "../../not_oracle/src/contracts/not_elector/NotElector.sol";
import "../interfaces/internal/IAuctionRoot.sol";
import "../interfaces/internal/IElector.sol";
import "../utils/Constants.sol";
import "../utils/ErrorCodes.sol";
import "../utils/Gas.sol";

import "ton-eth-bridge-token-contracts/contracts/interfaces/ITokenRoot.sol";
import "@broxus/contracts/contracts/libraries/MsgFlag.sol";
import "@broxus/contracts/contracts/utils/RandomNonce.sol";


contract NeverElectorAuction is NotElector, IElector, RandomNonce {
    event NoWinner();
    event Winner(address winner, uint128 price, uint128 amount);

    uint128 public _minLotSize;
    address public _auctionRoot;
    address public _neverRoot;

    constructor(
        uint signUpStageBeginningArg,
        uint signUpStageDurationArg,
        uint validationStageBeginningArg,
        uint validationStageDurationArg,
        address auctionRoot,
        address neverRoot
    ) public NotElector(
        signUpStageBeginningArg,
        signUpStageDurationArg,
        validationStageBeginningArg,
        validationStageDurationArg
    ) {
        _minLotSize = Constants.MIN_LOT_SIZE;
        _auctionRoot = auctionRoot;
        _neverRoot = neverRoot;
    }

    function transferAuctionRoot(address newOwner) public override {
        require(tvm.pubkey() == msg.pubkey() && msg.pubkey() != 0, Errors.WRONG_PUB_KEY);
        tvm.accept();
        IAuctionRoot(_auctionRoot).changeElector{
            value: Gas.TRANSFER_AUCTION_ROOT_VALUE,
            flag: MsgFlag.SENDER_PAYS_FEES,
            bounce: false
        }(newOwner);
    }

    function _afterRevealing(uint128 quotingPrice) internal override {
        IAuctionRoot(_auctionRoot).createAuction{
            value: Gas.CREATE_AUCTION_VALUE,
            flag: MsgFlag.SENDER_PAYS_FEES,
            bounce: false
        }(_minLotSize, quotingPrice);
    }

    function onAuctionFinish(bool success, address winner, uint128 price, uint128 amount) public override {
        require(msg.sender == _auctionRoot && _auctionRoot.value != 0, ErrorCodes.IS_NOT_ACTION_ROOT);
        if (!success) {
            emit NoWinner();
            return;
        }
        emit Winner(winner, price, amount);
        TvmCell empty;
        ITokenRoot(_neverRoot).mint{
            value: Gas.MINT_VALUE,
            flag: MsgFlag.SENDER_PAYS_FEES,
            bounce: false
        }(
            amount,                     // amount
            winner,                     // recipient
            Gas.DEPLOY_WALLET_GRAMS,    // deployWalletValue
            address(this),              // remainingGasTo
            true,                       // notify
            empty                       // payload
        );
    }

}
