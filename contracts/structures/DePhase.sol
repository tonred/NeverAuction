pragma ton-solidity >= 0.57.3;


enum DePhase {
    INITIALIZING,       // 0
    SUB_OPEN,           // 1
    SUB_CONFIRM,        // 2
    SUB_FINISH,         // 3
    WAITING_BID,        // 4
    BID_MADE,           // 5
    BID_CONFIRMED,      // 6
    WIN,                // 7
    DISTRIBUTION,       // 8
    LOSE,               // 9
    SLASHED             // 10
}
