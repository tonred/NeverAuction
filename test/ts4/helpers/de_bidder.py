from typing import Optional

from tonos_ts4 import ts4

from contracts.de_auction import DeAuction
from utils.options import Options
from utils.utils import random_salt
from utils.wallet import Wallet


class DeBidder:

    def __init__(self, de_auction: DeAuction, value: int, price: Optional[int]):
        self.de_auction = de_auction
        self.value = value
        self.price = price
        self.wallet = Wallet()
        self.de_participant = de_auction.root.create_de_participant(self.wallet)
        if self.price is not None:
            self.salt = random_salt()
            self.price_hash = self.de_participant.calc_price_hash(price, self.salt)
        else:
            self.price_hash = None

    def stake(self, value: int = None):
        value = value or self.value
        options = Options.from_grams(value + int(1.2 * ts4.GRAM))
        self.de_participant.stake(self.de_auction.address, value, self.price_hash, options)

    def remove_stake(self, value: int = None):
        value = value or self.value
        self.de_participant.remove_stake(self.de_auction.address, value)
        self.value -= value

    def confirm_price(self):
        assert self.price is not None, 'No price'
        self.de_participant.confirm_price(self.de_auction.address, self.price, self.salt)

    def claim(self):
        self.de_participant.claim(self.de_auction.address)
