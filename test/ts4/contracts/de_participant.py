import typing

from tonos_ts4 import ts4

from config import (
    DEFAULT_DESCRIPTION,
    DEFAULT_PRICES,
    DEFAULT_DEVIATION,
    DEFAULT_AGGREGATOR_FEE,
    DEFAULT_VALUE,
    DEFAULT_MSG_VALUE,
)
from contracts.de_auction import DeAuction
from utils.base_contract import BaseContract
from utils.options import Options
from utils.solidity_function import solidity_function, solidity_getter
from utils.wallet import Wallet

if typing.TYPE_CHECKING:
    from contracts.auction_root import AuctionRoot


class DeParticipant(BaseContract):

    def __init__(self, address: ts4.Address, root: 'AuctionRoot', owner: Wallet):
        super().__init__(address)
        self.root = root
        self.owner = owner

    @solidity_function()
    def create_de_auction(
            self,
            description: str = DEFAULT_DESCRIPTION,
            prices: dict = DEFAULT_PRICES,  # noqa (is not changed)
            deviation: int = DEFAULT_DEVIATION,
            fee: int = DEFAULT_AGGREGATOR_FEE,
            value: int = DEFAULT_VALUE,
            options=Options.from_grams(DEFAULT_MSG_VALUE),
    ) -> DeAuction:
        nonce = self.call_getter('_nonce') - 1
        de_auction_address = self.root.expected_de_auction(nonce)
        return DeAuction(de_auction_address, self.root, self.owner)

    @solidity_function()
    def stake(self, de_auction: ts4.Address, value: int, price_hash: int, options=Options(1)):
        pass

    @solidity_function()
    def remove_stake(self, de_auction: ts4.Address, value: int, options=Options(1)):
        pass

    @solidity_function()
    def confirm_stake(self, de_auction: ts4.Address, price: int, salt: int, options=Options(1)):
        pass

    @solidity_function()
    def claim(self, de_auction: ts4.Address, options=Options(1)):
        pass

    @solidity_getter()
    def calc_price_hash(self, price: int, salt: int) -> int:
        pass