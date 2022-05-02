from tonos_ts4 import ts4

from config import (
    BUILD_ARTIFACTS_PATH,
    VERBOSE,
    DEFAULT_FEE,
    DEFAULT_DEPOSIT,
    DEFAULT_OPEN_DURATION,
    DEFAULT_DE_BID_DURATION,
    DEFAULT_CONFIRM_DURATION,
    DEFAULT_SUB_OPEN_DURATION,
    DEFAULT_SUB_CONFIRM_DURATION,
    DEFAULT_MAKE_BID_DURATION,
)
from contracts.auction import Auction
from contracts.auction_root import AuctionRoot
from contracts.de_auction import DeAuction
from contracts.de_participant import DeParticipant
from helpers.bidder import Bidder
from helpers.token_type import DeAuctionTokenType
from utils.options import Options
from utils.wallet import Wallet


class Deployer:

    def __init__(self, now: int = None, token_type: DeAuctionTokenType = DeAuctionTokenType.TIP3):
        ts4.reset_all()
        ts4.init(BUILD_ARTIFACTS_PATH, verbose=VERBOSE)
        if now is not None:
            ts4.core.set_now(0)
        self.token_type = token_type
        self.auction_root = self.create_auction_root()
        self.auction = self.create_auction()
        self.aggregator, self.de_auction = self.create_de_auction()

    def create_auction_root(self) -> AuctionRoot:
        elector = self.create_wallet()
        bid_code = ts4.load_code_cell('Bid')
        auction_root = AuctionRoot({
            'elector': elector.address,
            'auctionConfig': {
                'fee': DEFAULT_FEE,
                'deposit': DEFAULT_DEPOSIT,
                'openDuration': DEFAULT_OPEN_DURATION,
                'deBidDuration': DEFAULT_DE_BID_DURATION,
                'confirmDuration': DEFAULT_CONFIRM_DURATION,
                'bidCode': bid_code,
            },
            'deAuctionGlobalConfig': {
                'subOpenDuration': DEFAULT_SUB_OPEN_DURATION,
                'subConfirmDuration': DEFAULT_SUB_CONFIRM_DURATION,
                'makeBidDuration': DEFAULT_MAKE_BID_DURATION,
                'initDetails': self.token_type.value,
            },
        }, elector)

        platform_code = ts4.load_code_cell('Platform')
        auction_code = ts4.load_code_cell('Auction')
        de_auction_code = ts4.load_code_cell('DeAuction' + self.token_type.name)
        de_participant_code = ts4.load_code_cell('DeParticipant')
        elector.run_target(auction_root, options=Options(0.3), method='setCodes', params={
            'platformCode': platform_code.raw_,
            'auctionCode': auction_code.raw_,
            'deAuctionCode': de_auction_code.raw_,
            'deParticipantCode': de_participant_code.raw_,
        })
        return auction_root

    def create_auction(self) -> Auction:
        return self.auction_root.create_auction()

    def create_de_auction(self) -> (DeParticipant, DeAuction):
        aggregator = self.create_aggregator()
        de_participant = self.auction_root.create_de_participant(aggregator)
        de_auction = de_participant.create_de_auction(self.token_type)
        return de_participant, de_auction

    @staticmethod
    def create_aggregator() -> Wallet:
        return Wallet(nickname='Aggregator', balance=int(1e6 * ts4.GRAM))

    def create_bidder(self, price: int, amount: int) -> Bidder:
        return Bidder(self.auction, price, amount)

    @staticmethod
    def create_wallet(**kwargs) -> Wallet:
        return Wallet(**kwargs)
