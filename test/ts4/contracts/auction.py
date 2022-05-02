import typing

from tonos_ts4 import ts4

from config import DEFAULT_BID_VALUE
from utils.base_contract import BaseContract
from utils.options import Options
from utils.solidity_function import solidity_function, solidity_getter
from utils.wallet import Wallet

if typing.TYPE_CHECKING:
    from contracts.auction_root import AuctionRoot


class Auction(BaseContract):

    def __init__(self, address: ts4.Address, root: 'AuctionRoot'):
        super().__init__(address)
        self.root = root

    @solidity_function(send_as='wallet')
    def make_bid(self, wallet: Wallet, hash: int, options=Options(DEFAULT_BID_VALUE)):
        pass

    @solidity_function(send_as='wallet')
    def make_de_bid(self, wallet: Wallet, nonce: int, hash: int, options=Options(DEFAULT_BID_VALUE)):
        pass

    @solidity_function(send_as='wallet')
    def remove_bid(self, wallet: Wallet, hash: int, options=Options(0.5)):
        pass

    @solidity_function(send_as='wallet')
    def confirm_bid(self, wallet: Wallet, price: int, amount: int, salt: int, options: Options):
        pass

    @solidity_getter()
    def calc_bid_hash(self, price: int, amount: int, sender: ts4.Address, salt: int) -> int:
        pass

    @solidity_function(send_as='wallet')
    def finish(self, wallet: Wallet, options=Options(0.5)):
        pass
