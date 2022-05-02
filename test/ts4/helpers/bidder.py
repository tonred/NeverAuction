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

    def make_bid(self):
        self.auction.make_bid(self.wallet, self.hash)

    def remove_bid(self):
        self.auction.remove_bid(self.wallet, self.hash)

    def confirm_bid(self, value: int = None):
        if value is None:
            value = self.price * self.amount
        options = Options.from_grams(value)
        self.auction.confirm_bid(self.wallet, self.price, self.amount, self.salt, options)
