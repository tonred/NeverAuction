pragma ton-solidity >= 0.57.3;


library Gas {

    // Auction
    uint128 constant DEPLOY_BID_VALUE               = 0.5 ton;
    uint128 constant REMOVE_BID_VALUE               = 0.3 ton;
    uint128 constant CONFIRM_BID_VALUE              = 0.3 ton;
    uint128 constant ON_WIN_VALUE                   = 0.5 ton;

    // Auction Root
    uint128 constant DEPLOY_AUCTION_VALUE           = 1 ton;  // more than ON_WIN_VALUE
    uint128 constant DEPLOY_DE_PARTICIPANT_VALUE    = 1 ton;

    // DeAuction
    uint128 constant DE_AUCTION_ACTION_VALUE        = 0.5 ton;
    uint128 constant DE_AUCTION_PING_FINISH_VALUE   = 0.3 ton;
    uint128 constant DEPLOY_WALLET_GRAMS            = 0.3 ton;
    uint128 constant DEPLOY_WALLET_VALUE            = 0.5 ton;  // more than DEPLOY_WALLET_GRAMS
    uint128 constant TRANSFER_TIP3_VALUE            = 0.5 ton;  // more than DEPLOY_WALLET_GRAMS
    uint128 constant TRANSFER_ECC_VALUE             = 0.2 ton;

    // DeParticipant
    uint128 constant DE_AUCTION_INIT_VALUE          = 3 ton;
    uint128 constant DE_PARTICIPANT_ACTION_VALUE    = 1 ton;

    // Elector
    uint128 constant MINT_VALUE                     = 1 ton;
    uint128 constant CREATE_AUCTION_VALUE           = 1.2 ton;  // more than DEPLOY_AUCTION_VALUE

}
