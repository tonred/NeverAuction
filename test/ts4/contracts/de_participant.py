import typing

from tonos_ts4 import ts4

from config import (
    DEFAULT_DESCRIPTION,
    DEFAULT_PRICES,
    DEFAULT_DEVIATION,
    DEFAULT_AGGREGATOR_FEE,
    DEFAULT_AGGREGATOR_VALUE,
    DEFAULT_AGGREGATOR_MSG_VALUE,
)
from contracts.de_auction import DeAuction
from helpers.token_type import DeAuctionTokenType
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

    @solidity_function(ignore=('token_type',))
    def create_de_auction(
            self,
            token_type: DeAuctionTokenType,
            description: str = DEFAULT_DESCRIPTION,
            prices: dict = DEFAULT_PRICES,  # noqa (is not changed)
            deviation: int = DEFAULT_DEVIATION,
            fee: int = DEFAULT_AGGREGATOR_FEE,
            value: int = DEFAULT_AGGREGATOR_VALUE,
            options=Options.from_grams(DEFAULT_AGGREGATOR_MSG_VALUE),
    ) -> DeAuction:
        nonce = self.root.call_getter('_nonce') - 1
        de_auction_address = self.root.expected_de_auction(nonce)
        abi_name = 'DeAuction' + token_type.name
        return DeAuction(de_auction_address, abi_name, self.root, self.owner)

    @solidity_function()
    def stake(self, de_auction: ts4.Address, value: int, price_hash: int, options: Options):
        pass

    @solidity_function()
    def remove_stake(self, de_auction: ts4.Address, value: int, options=Options(1.2)):
        pass

    @solidity_function()
    def confirm_price(self, de_auction: ts4.Address, price: int, salt: int, options=Options(1.2)):
        pass

    @solidity_function()
    def claim(self, de_auction: ts4.Address, options=Options(1.2)):
        pass

    @solidity_getter()
    def calc_price_hash(self, price: int, salt: int) -> int:
        pass
