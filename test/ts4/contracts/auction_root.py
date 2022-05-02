from tonos_ts4 import ts4

from config import DEFAULT_MIN_LOT_SIZE, DEFAULT_QUOTING_PRICE
from contracts.auction import Auction
from contracts.de_participant import DeParticipant
from utils.options import Options
from utils.solidity_function import solidity_function, solidity_getter
from utils.utils import random_address
from utils.wallet import Wallet


class AuctionRoot(ts4.BaseContract):

    def __init__(self, ctor_params: dict, elector: Wallet):
        super().__init__(
            'AuctionRoot',
            ctor_params,
            nickname='AuctionRoot',
            override_address=random_address(),
        )
        self.elector = elector

    @solidity_getter(responsible=True)
    def current_auction(self) -> ts4.Address:
        pass

    @solidity_function(send_as='elector')
    def create_auction(
            self,
            min_lot_size: int = DEFAULT_MIN_LOT_SIZE,
            quoting_price: int = DEFAULT_QUOTING_PRICE,
            options=Options(1.2)
    ) -> Auction:
        auction_address = self.current_auction()
        return Auction(auction_address, self)

    @solidity_function(send_as='owner')
    def create_de_participant(self, owner: Wallet, options=Options(1.2)) -> DeParticipant:
        de_participant_address = self.expected_de_participant(owner.address)
        return DeParticipant(de_participant_address, self, owner)

    @solidity_getter(responsible=True)
    def expected_de_participant(self, owner: ts4.Address) -> ts4.Address:
        pass

    @solidity_getter(responsible=True)
    def expected_de_auction(self, nonce: int) -> ts4.Address:
        pass
