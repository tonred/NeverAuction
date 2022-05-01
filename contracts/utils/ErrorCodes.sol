pragma ton-solidity >= 0.57.3;


library ErrorCodes {

    // Common
    uint16 constant IS_NOT_ELECTOR          = 1000;
    uint16 constant IS_NOT_ACTION_ROOT      = 1001;
    uint16 constant IS_NOT_AUCTION          = 1002;
    uint16 constant IS_NOT_DE_PARTICIPANT   = 1003;
    uint16 constant IS_NOT_DE_AUCTION       = 1004;
    uint16 constant IS_NOT_BID              = 1005;
    uint16 constant WRONG_PHASE             = 1006;

    // Auction Root
    uint16 constant ALREADY_RUNNING         = 2000;
    uint16 constant LOW_FEE_VALUE           = 2001;
    uint16 constant LOW_DEPOSIT_VALUE       = 2002;

    // Auction
    uint16 constant LOW_PRICE               = 3000;
    uint16 constant LOW_AMOUNT              = 3001;
    uint16 constant LOW_MSG_VALUE           = 3002;

    // DeAuction
    uint16 constant IS_NOT_AGGREGATOR       = 4000;
    uint16 constant PRICE_OUT_OF_RANGE      = 4001;
    uint16 constant IS_NOT_TOKEN_ROOT       = 4002;
    uint16 constant IS_NOT_TOKEN_WALLET     = 4003;

    // DeParticipant
    uint16 constant IS_NOT_OWNER            = 5000;
    uint16 constant LOCKED                  = 5001;
    uint16 constant LOW_VALUE               = 5002;
    uint16 constant VALUE_MORE_THAN_STAKE   = 5003;
    uint16 constant WRONG_HASH              = 5004;
    uint16 constant NO_STAKE                = 5005;

}
