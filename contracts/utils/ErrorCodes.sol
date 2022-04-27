pragma ton-solidity >= 0.57.3;


library ErrorCodes {
    // todo is all used?

    uint16 constant IS_NOT_ELECTOR = 1000;  // todo move all if ones
    uint16 constant IS_NOT_ACTION_ROOT = 1000;
    uint16 constant IS_NOT_DE_PARTICIPANT = 1000;
    uint16 constant IS_NOT_DE_AUCTION = 1000;
    uint16 constant IS_NOT_AUCTION = 1000;
    uint16 constant IS_NOT_BID = 1000;

    // Auction
    uint16 constant WRONG_PHASE = 1000;
    uint16 constant LOW_FEE_VALUE = 1000;
    uint16 constant LOW_DEPOSIT_VALUE = 1000;
    uint16 constant TOO_SHORT_DURATION = 1000;
    uint16 constant LOW_MSG_VALUE = 1000;  // todo up ?

    // Auction Root (todo up)
    uint16 constant AUCTION_IS_ALREADY_RUNNING = 1000;

    // DeAuction
    uint16 constant IS_NOT_AGGREGATOR = 1000;

    uint16 constant IS_NOT_TOKEN_ROOT = 1000; // todo last DeAuction error
    uint16 constant IS_NOT_TOKEN_WALLET = 1000; // todo last DeAuction error

}
