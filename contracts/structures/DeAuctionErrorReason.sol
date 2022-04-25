pragma ton-solidity >= 0.57.3;


enum DeAuctionErrorReason {
    OK,
    NO_ACTIVE_AUCTION,
    WRONG_PRICE_RANGE,
    TOO_LONG_DESCRIPTION
}
