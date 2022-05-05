import unittest
from enum import IntEnum

from config import *
from helpers.deployer import Deployer
from utils.options import Options
from utils.utils import ZERO_ADDRESS
from utils.wallet import Wallet

DEFAULT_PRICE = 4 * ts4.GRAM
DEFAULT_AMOUNT = 500 * ts4.GRAM


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
        self.assertDictEqual(details, expected_details, 'Wrong details')
        self._check_phase(Phase.OPEN)

    def test_phases(self):
        # have at least 1 bid in order to not skip phases
        wallet = self.deployer.create_wallet()
        self.auction.make_bid(wallet, 0)
        self._check_phase(Phase.OPEN)

        ts4.core.set_now(DE_BID_TIME)
        self._check_phase(Phase.DE_BID)

        ts4.core.set_now(CONFIRM_TIME)
        self._check_phase(Phase.CONFIRM)

        ts4.core.set_now(FINISH_TIME)
        self._check_phase(Phase.FINISH)

    def test_make_bid(self):
        bidder = self.deployer.create_bidder(DEFAULT_PRICE, DEFAULT_AMOUNT)
        balance_before = bidder.wallet.balance
        bidder.make_bid()
        self._check_balance(bidder.wallet, balance_before - DEFAULT_DEPOSIT)

    def test_remove_bid(self):
        bidder = self.deployer.create_bidder(DEFAULT_PRICE, DEFAULT_AMOUNT)
        balance_before = bidder.wallet.balance
        bidder.make_bid()
        bidder.remove_bid()
        remove_bid_value = int(0.3 * ts4.GRAM)
        self._check_balance(bidder.wallet, balance_before - DEFAULT_FEE - remove_bid_value)

    def test_remove_bid_wrong_phase(self):
        bidder = self.deployer.create_bidder(DEFAULT_PRICE, DEFAULT_AMOUNT)
        bidder.make_bid()
        ts4.core.set_now(CONFIRM_TIME)
        self.auction.remove_bid(bidder.wallet, bidder.hash, Options(0.5, expect_ec=1006))

    def test_make_bid_wrong_phase(self):
        ts4.core.set_now(DE_BID_TIME)
        wallet = self.deployer.create_wallet()
        self.auction.make_bid(wallet, 0, Options(DEFAULT_BID_VALUE, expect_ec=1006))

    def test_make_de_bid_wrong(self):
        ts4.core.set_now(DE_BID_TIME)
        wallet = self.deployer.create_wallet()
        self.auction.make_de_bid(wallet, 0, 0, Options(DEFAULT_BID_VALUE, expect_ec=1004))

    def test_confirm_bid(self):
        bidder = self.deployer.create_bidder(DEFAULT_PRICE, DEFAULT_AMOUNT)
        balance_before = bidder.wallet.balance
        bidder.make_bid()
        ts4.core.set_now(CONFIRM_TIME)
        bidder.confirm_bid()
        self._check_balance(bidder.wallet, balance_before - DEFAULT_FEE - bidder.value())

    def test_confirm_bid_min_value(self):
        bidder = self.deployer.create_bidder(DEFAULT_PRICE, DEFAULT_AMOUNT)
        balance_before = bidder.wallet.balance
        bidder.make_bid()
        ts4.core.set_now(CONFIRM_TIME)
        value = bidder.value() - DEFAULT_DEPOSIT + DEFAULT_FEE
        bidder.confirm_bid(value)
        self._check_balance(bidder.wallet, balance_before - DEFAULT_FEE - bidder.value())

    def test_confirm_bid_low_value(self):
        bidder = self.deployer.create_bidder(DEFAULT_PRICE, DEFAULT_AMOUNT)
        bidder.make_bid()
        ts4.core.set_now(CONFIRM_TIME)
        value = bidder.value() - DEFAULT_DEPOSIT + DEFAULT_FEE - 1
        options = Options.from_grams(value, expect_ec=3002)
        self.auction.confirm_bid(bidder.wallet, bidder.price, bidder.amount, bidder.salt, options)

    def test_twice_confirm_bid(self):
        bidder_keep = self.deployer.create_bidder(DEFAULT_PRICE, DEFAULT_AMOUNT)  # in order to keep confirm phase
        bidder = self.deployer.create_bidder(DEFAULT_PRICE, DEFAULT_AMOUNT)
        bidder_keep.make_bid()
        bidder.make_bid()
        ts4.core.set_now(CONFIRM_TIME)
        options = Options.from_grams(bidder.value())
        self.auction.confirm_bid(bidder.wallet, bidder.price, bidder.amount, bidder.salt, options)
        self.auction.confirm_bid(bidder.wallet, bidder.price, bidder.amount, bidder.salt, options)
        # if bid is not confirmed, then phase is not changed
        self._check_phase(Phase.CONFIRM)

    def test_no_winner(self):
        bidder = self.deployer.create_bidder(DEFAULT_PRICE, DEFAULT_AMOUNT)
        bidder.make_bid()
        ts4.core.set_now(FINISH_TIME)
        self.auction.finish(bidder.wallet)
        winner = self.auction.call_responsible('getWinner')
        self.assertEqual(winner['owner'], ZERO_ADDRESS, 'Wrong winner')

    def test_no_bidder_no_winner(self):
        ts4.core.set_now(CONFIRM_TIME)  # confirm time, but no bidder, so auction is finished
        random_guy = self.deployer.create_wallet()
        self.auction.finish(random_guy)
        winner = self.auction.call_responsible('getWinner')
        self.assertEqual(winner['owner'], ZERO_ADDRESS, 'Wrong winner')

    def test_one_bidder(self):
        bidder = self.deployer.create_bidder(DEFAULT_PRICE, DEFAULT_AMOUNT)
        init_balance = bidder.wallet.balance
        bidder.make_bid()
        ts4.core.set_now(CONFIRM_TIME)
        bidder.confirm_bid()

        random_guy = self.deployer.create_wallet()
        self.auction.finish(random_guy)
        winner = self.auction.call_responsible('getWinner')
        self.assertDictEqual(winner, bidder.bid_data(), 'Wrong winner')
        self._check_balance(bidder.wallet, init_balance - DEFAULT_FEE - bidder.value() + ON_WIN_VALUE)

    def test_many_bidder(self):
        second_price = DEFAULT_PRICE + int(0.2 * ts4.GRAM)
        second_amount = DEFAULT_AMOUNT + 100
        third_price = DEFAULT_PRICE + int(0.3 * ts4.GRAM)
        third_amount = DEFAULT_AMOUNT + 50
        bidder_1 = self.deployer.create_bidder(DEFAULT_PRICE, DEFAULT_AMOUNT)  # return immediately in confirmation
        bidder_2 = self.deployer.create_bidder(second_price, second_amount)  # return after confirmation of third bid
        bidder_3 = self.deployer.create_bidder(third_price, third_amount)  # winner
        init_balance = bidder_1.wallet.balance

        bidder_1.make_bid()
        bidder_2.make_bid()
        bidder_3.make_bid()
        ts4.core.set_now(CONFIRM_TIME)
        bidder_1.confirm_bid()
        bidder_2.confirm_bid()
        bidder_3.confirm_bid()

        random_guy = self.deployer.create_wallet()
        self.auction.finish(random_guy)
        winner = self.auction.call_responsible('getWinner')
        expected_winner = {
            'owner': bidder_3.wallet.address,
            'price': bidder_2.price,  # second price
            'amount': bidder_3.amount,
            'value': bidder_2.price * bidder_3.amount // ts4.GRAM,
        }
        self.assertDictEqual(winner, expected_winner, 'Wrong winner')

        self._check_balance(bidder_1.wallet, init_balance - DEFAULT_FEE)
        self._check_balance(bidder_2.wallet, init_balance - DEFAULT_FEE)
        self._check_balance(bidder_3.wallet, init_balance - DEFAULT_FEE - expected_winner['value'] + ON_WIN_VALUE)

    def test_finish_wrong_phase(self):
        bidder = self.deployer.create_bidder(DEFAULT_PRICE, DEFAULT_AMOUNT)
        bidder.make_bid()
        ts4.core.set_now(CONFIRM_TIME)  # wrong phase
        self.auction.finish(bidder.wallet, Options(0.5, expect_ec=1006))
        ts4.core.set_now(FINISH_TIME)  # right phase
        self.auction.finish(bidder.wallet, Options(0.5))

    def _check_phase(self, expected: Phase):
        self.assertEqual(self.auction.call_responsible('getPhase'), expected.value, 'Wrong phase')

    def _check_balance(self, wallet: Wallet, expected: int):
        self.assertEqual(
            wallet.balance, expected, f'Wrong balance, actual={wallet.balance / 1e9}, expected={expected / 1e9}'
        )
