pragma ton-solidity >= 0.57.3;


library Gas {

    // todo
    // Auction
    uint128 constant DEPLOY_BID_VALUE = 1 ton;
    uint128 constant REMOVE_BID_VALUE = 1 ton;
    uint128 constant CONFIRM_BID_VALUE = 1 ton;
    uint128 constant ON_WIN_VALUE = 1 ton;

    // Auction Root
    uint128 constant DEPLOY_AUCTION_VALUE = 1 ton;
    uint128 constant DEPLOY_DE_PARTICIPANT_VALUE = 1 ton;

    // DeAuction
    uint128 constant DE_AUCTION_ACTION_VALUE = 1 ton;
    uint128 constant FINISH_AUCTION = 1 ton;
    // todo lasts
    uint128 constant DEPLOY_WALLET_GRAMS = 1 ton;
    uint128 constant DEPLOY_WALLET_VALUE = 2 ton;  // more than DEPLOY_WALLET_GRAMS
    uint128 constant TRANSFER_VALUE = 1 ton;

    // DeParticipant
    uint128 constant DE_AUCTION_INIT_VALUE = 5 ton;
    uint128 constant DE_PARTICIPANT_ACTION_VALUE = 1 ton;
}
