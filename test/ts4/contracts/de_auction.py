import typing

from tonos_ts4 import ts4

from config import DEFAULT_DEPOSIT
from utils.base_contract import BaseContract
from utils.options import Options
from utils.solidity_function import solidity_function, solidity_getter
from utils.wallet import Wallet

if typing.TYPE_CHECKING:
    from contracts.auction_root import AuctionRoot


class DeAuction(BaseContract):

    def __init__(self, address: ts4.Address, abi_name: str, root: 'AuctionRoot', aggregator: Wallet):
        super().__init__(address, abi_name)
        self.root = root
        self.aggregator = aggregator

    def auction(self) -> ts4.Address:
        return self.root.current_auction()

    def total_stake(self) -> int:
        return self.call_responsible('getStakes')[0]

    @solidity_function(send_as='wallet')
    def finish_sub_voting(self, wallet: Wallet, options=Options(0.3)):
        pass

    @solidity_getter()
    def allowed_price(self) -> dict:
        pass

    @solidity_getter()
    def calc_bid_hash(self, price: int, salt: int) -> dict:
        pass

    @solidity_function(send_as='aggregator')
    def make_bid(self, hash: int, options=Options.from_grams(DEFAULT_DEPOSIT + ts4.GRAM)):
        pass

    @solidity_function(send_as='aggregator')
    def confirm_bid(self, price: int, salt: int, options=Options(1)):
        pass

    @solidity_function(send_as='wallet')
    def ping_auction_finish(self, wallet: Wallet, options=Options(1)):
        pass

    @solidity_getter()
    def check_aggregator(self) -> bool:
        pass

    @solidity_function(send_as='wallet')
    def slash(self, wallet: Wallet, options=Options(1)):
        pass
