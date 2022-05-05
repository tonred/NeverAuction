pragma ton-solidity >= 0.57.3;

pragma AbiHeader time;
pragma AbiHeader expire;
pragma AbiHeader pubkey;

import "../AuctionRoot.sol";


contract TestAuctionRoot is AuctionRoot {

    constructor(
        address elector,
        AuctionConfig auctionConfig,
        DeAuctionGlobalConfig deAuctionGlobalConfig
    ) public AuctionRoot (elector, auctionConfig, deAuctionGlobalConfig) {}

    function createAuctionTest(uint128 minLotSize, uint128 quotingPrice) public cashBack {
        require(!_isActionNow, ErrorCodes.ALREADY_RUNNING);
        require(_auctionConfig.fee > Gas.DEPLOY_BID_VALUE, ErrorCodes.LOW_FEE_VALUE);
        require(_auctionConfig.deposit > _auctionConfig.fee, ErrorCodes.LOW_DEPOSIT_VALUE);
        TvmCell stateInit = _buildAuctionStateInit(address(this), _nonce++);
        TvmCell initialParams = abi.encode(_auctionConfig, minLotSize, quotingPrice);
        _auction = new Platform{
            stateInit: stateInit,
            value: Gas.DEPLOY_AUCTION_VALUE,
            flag: MsgFlag.SENDER_PAYS_FEES,
            bounce: false
        }(_auctionCode, initialParams, address(0));
        emit NewAuction(_auction);
        _isActionNow = true;
    }

}
