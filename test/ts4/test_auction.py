import unittest
from enum import IntEnum

from config import *
from helpers.deployer import Deployer
from utils.options import Options
from utils.utils import random_salt
from utils.wallet import Wallet


class Phase(IntEnum):
    OPEN = 0
    DE_BID = 1
    CONFIRM = 2
    FINISH = 3
    DONE = 4


class TestAuction(unittest.TestCase):

    def setUp(self):
        self.deployer = Deployer(now=0)
        self.auction = self.deployer.auction

    def test_init(self):
        details = self.auction.call_responsible('getDetails')
        now = ts4.core.get_now()
        expected_details = {
            'root': self.deployer.auction_root.address,
            'fee': DEFAULT_FEE,
            'deposit': DEFAULT_DEPOSIT,
            'deBidTime': DE_BID_TIME,
            'confirmTime': CONFIRM_TIME,
            'finishTime': FINISH_TIME,
            'minLotSize': DEFAULT_MIN_LOT_SIZE,
            'quotingPrice': DEFAULT_QUOTING_PRICE,
        }
        print(expected_details, now)
        self.assertDictEqual(details, expected_details, 'Wrong details')
        self._check_phase(Phase.OPEN)

    def test_phases(self):
        # have at least 1 bid in order to not skip phases
        wallet = Wallet()
        self.auction.make_bid(wallet, 0)
        ts4.core.set_now(DEFAULT_OPEN_DURATION)
        self._check_phase(Phase.DE_BID)
        ts4.core.set_now(DEFAULT_OPEN_DURATION + DEFAULT_DE_BID_DURATION)
        self._check_phase(Phase.CONFIRM)
        ts4.core.set_now(DEFAULT_OPEN_DURATION + DEFAULT_DE_BID_DURATION + DEFAULT_CONFIRM_DURATION)
        self._check_phase(Phase.FINISH)

    def test_make_bid(self):
        wallet = Wallet()
        balance_before = wallet.balance
        self.auction.make_bid(wallet, 0)
        self._check_balance(wallet, balance_before - DEFAULT_DEPOSIT)

    def test_remove_bid(self):
        wallet = Wallet()
        balance_before = wallet.balance
        self.auction.make_bid(wallet, 0)
        self.auction.remove_bid(wallet, 0)
        remove_bid_value = int(0.3 * ts4.GRAM)
        self._check_balance(wallet, balance_before - DEFAULT_FEE - remove_bid_value)

    def test_make_bid_wrong_phase(self):
        ts4.core.set_now(DEFAULT_OPEN_DURATION)
        wallet = Wallet()
        self.auction.make_bid(wallet, 0, Options(DEFAULT_BID_VALUE, expect_ec=1006))

    def test_make_de_bid_wrong(self):
        ts4.core.set_now(DEFAULT_OPEN_DURATION)
        wallet = Wallet()
        self.auction.make_de_bid(wallet, 0, 0, Options(DEFAULT_BID_VALUE, expect_ec=1004))

    def test_confirm_bid(self):
        wallet = Wallet()
        balance_before = wallet.balance
        price = 4 * ts4.GRAM
        amount = 123
        salt = random_salt()
        bid_hash = self.auction.calc_bid_hash(price, amount, wallet.address, salt)
        self.auction.make_bid(wallet, bid_hash)
        ts4.core.set_now(CONFIRM_TIME)
        options = Options.from_grams(price * amount)
        self.auction.confirm_bid(wallet, price, amount, salt, options)
        self._check_balance(wallet, balance_before - DEFAULT_FEE - price * amount)

    def _check_phase(self, expected: Phase):
        self.assertEqual(self.auction.call_responsible('getPhase'), expected.value, 'Wrong phase')

    def _check_balance(self, wallet: Wallet, expected: int):
        self.assertEqual(
            wallet.balance, expected, f'Wrong balance, actual={wallet.balance / 1e9}, expected={expected / 1e9}'
        )
