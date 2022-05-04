from tonos_ts4 import ts4

from contracts.auction import Auction
from utils.options import Options
from utils.utils import random_salt
from utils.wallet import Wallet


class Bidder:

    def __init__(self, auction: Auction, price: int, amount: int):
        self.auction = auction
        self.wallet = Wallet()
        self.price = price
        self.amount = amount
        self.salt = random_salt()
        self.hash = auction.calc_bid_hash(price, amount, self.wallet.address, self.salt)

    def value(self) -> int:
        return self.price * self.amount // ts4.GRAM

    def bid_data(self) -> dict:
        return {
            'owner': self.wallet.address,
            'price': self.price,
            'amount': self.amount,
            'value': self.value(),
        }

    def make_bid(self):
        self.auction.make_bid(self.wallet, self.hash)

    def remove_bid(self):
        self.auction.remove_bid(self.wallet, self.hash)

    def confirm_bid(self, value: int = None):
        if value is None:
            value = self.value()
        options = Options.from_grams(value)
        self.auction.confirm_bid(self.wallet, self.price, self.amount, self.salt, options)
