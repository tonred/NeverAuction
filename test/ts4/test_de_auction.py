import unittest
from enum import IntEnum

from config import *
from contracts.de_participant import DeParticipant
from helpers.deployer import Deployer
from utils.options import Options
from utils.utils import random_salt
from utils.wallet import Wallet


class DePhase(IntEnum):
    INITIALIZING = 0,
    SUB_OPEN = 1,
    SUB_CONFIRM = 2,
    SUB_FINISH = 3,
    WAITING_BID = 4,
    BID_MADE = 5,
    BID_CONFIRMED = 6,
    WIN = 7,
    DISTRIBUTION = 8,
    LOSE = 9,
    SLASHED = 10


class TestDeAuction(unittest.TestCase):

    def setUp(self):
        self.deployer = Deployer(now=0)
        self.auction = self.deployer.auction
        self.de_auction = self.deployer.de_auction
        self.aggregator_de_participant = self.deployer.aggregator_de_participant
        self.aggregator = self.aggregator_de_participant.owner

    def test_init(self):
        details = self.de_auction.call_responsible('getDetails')
        expected_details = (
            self.deployer.auction_root.address,
            self.auction.address,
            {
                'init': {
                    'description': DEFAULT_DESCRIPTION,
                    'prices': DEFAULT_PRICES,
                    'deviation': DEFAULT_DEVIATION,
                    'aggregatorFee': DEFAULT_AGGREGATOR_FEE,
                    'aggregator': self.aggregator.address,
                    'aggregatorStake': DEFAULT_AGGREGATOR_VALUE,
                },
                'global': {
                    'subOpenDuration': DEFAULT_SUB_OPEN_DURATION,
                    'subConfirmDuration': DEFAULT_SUB_CONFIRM_DURATION,
                    'makeBidDuration': DEFAULT_MAKE_BID_DURATION,
                    'initDetails': self.deployer.token_type.value,
                },
            }
        )
        self.assertTupleEqual(details, expected_details, 'Wrong details')
        self._check_phase(DePhase.SUB_OPEN)
        stakes = self.de_auction.call_responsible('getStakes')
        self.assertEqual(stakes, (DEFAULT_AGGREGATOR_VALUE, DEFAULT_AGGREGATOR_VALUE), 'Wrong stakes')
        times = self.de_auction.call_responsible('getTimes')
        expected_times = (SUB_CONFIRM_TIME, SUB_MAKE_BID_TIME)
        self.assertEqual(times, expected_times, 'Wrong times')

    def test_phase(self):
        self._check_phase(DePhase.SUB_OPEN)
        bidder = self.deployer.create_de_bidder(ts4.GRAM, price=int(0.39 * ts4.GRAM))
        bidder.stake()

        ts4.core.set_now(SUB_CONFIRM_TIME)
        bidder.confirm_price()
        self._check_phase(DePhase.SUB_CONFIRM)

        ts4.core.set_now(SUB_MAKE_BID_TIME)
        bidder.stake(1)  # don't affect, only for calling `doUpdate`
        self._check_phase(DePhase.SUB_FINISH)

        self.de_auction.finish_sub_voting(bidder.wallet)
        self._check_phase(DePhase.WAITING_BID)

        allowed_price = self.de_auction.allowed_price()
        price = (allowed_price['min'] + allowed_price['max']) // 2
        salt = random_salt()
        bid_hash = self.de_auction.calc_bid_hash(price, salt)
        self.de_auction.make_bid(bid_hash)
        self._check_phase(DePhase.BID_MADE)

        ts4.core.set_now(CONFIRM_TIME)
        self.de_auction.confirm_bid(price, salt)
        self._check_phase(DePhase.BID_CONFIRMED)

        ts4.core.set_now(FINISH_TIME)
        self.auction.finish(bidder.wallet)
        self._check_phase(DePhase.WIN)

        # todo distribution

    def test_change_stake(self):
        bidder = self.deployer.create_de_bidder(100 * ts4.GRAM, price=None)
        self.assertEqual(self._de_participant_stake(bidder.de_participant), 0, 'Wrong stake')
        bidder.stake()
        self.assertEqual(self._de_participant_stake(bidder.de_participant), 100 * ts4.GRAM, 'Wrong stake')
        bidder.stake(5 * ts4.GRAM)
        self.assertEqual(self._de_participant_stake(bidder.de_participant), 105 * ts4.GRAM, 'Wrong stake')
        bidder.remove_stake(50 * ts4.GRAM)
        self.assertEqual(self._de_participant_stake(bidder.de_participant), 55 * ts4.GRAM, 'Wrong stake')

    def test_remove_big_stake(self):
        de_participant = self.deployer.create_de_participant()
        value = 100 * ts4.GRAM
        options = Options.from_grams(value + int(1.2 * ts4.GRAM))
        de_participant.stake(self.de_auction.address, value, price_hash=0, options=options)
        de_participant.remove_stake(self.de_auction.address, 100 * ts4.GRAM + 1, options=Options(1.2, expect_ec=5003))
        self.assertEqual(self._de_participant_stake(de_participant), 100 * ts4.GRAM, 'Wrong stake')

    def test_aggregator_remove_stake(self):
        balance_before = self.aggregator_de_participant.owner.balance
        stake_before = self._de_participant_stake(self.aggregator_de_participant)
        self.aggregator_de_participant.remove_stake(self.de_auction.address, 1)
        stake_after = self._de_participant_stake(self.aggregator_de_participant)
        self.assertEqual(stake_before, stake_after, 'Wrong stake')
        self._check_balance(self.aggregator_de_participant.owner, balance_before)

    def test_twice_price_confirm(self):
        bidder = self.deployer.create_de_bidder(100 * ts4.GRAM, price=int(0.4 * ts4.GRAM))
        bidder.stake()
        ts4.core.set_now(SUB_CONFIRM_TIME)
        # first confirmation (ok)
        bidder.confirm_price()
        # second confirmation (with exception)
        options = Options(1.2, expect_ec=5004)
        bidder.de_participant.confirm_price(self.de_auction.address, bidder.price, bidder.salt, options)

    def test_wrong_price_confirm(self):
        bidder = self.deployer.create_de_bidder(100 * ts4.GRAM, price=int(0.4 * ts4.GRAM))
        bidder.stake()
        ts4.core.set_now(SUB_CONFIRM_TIME)
        options_ec = Options(1.2, expect_ec=5004)
        bidder.de_participant.confirm_price(self.de_auction.address, bidder.price, 10101010101, options_ec)
        bidder.de_participant.confirm_price(self.de_auction.address, bidder.price, bidder.salt, Options(1.2))

    def test_price_calculating(self):
        self._prepare_bidders()
        average_price = ts4.GRAM * (100 * 0.36 + 70 * 0.37 + 80 * 0.38) // (100 + 70 + 80)
        delta = average_price * DEFAULT_DEVIATION // PERCENT_DENOMINATOR
        expected_allowed_price = {
            'min': average_price - delta,
            'max': average_price + delta,
        }
        allowed_price = self.de_auction.allowed_price()
        self.assertDictEqual(expected_allowed_price, allowed_price, 'Wrong allowed price')

    def test_distribution(self):
        bidders = self._win_auction()
        # todo check distribution

    def test_two_de_auctions(self):
        random_guy = self.deployer.create_wallet()
        de_auction_1 = self.de_auction
        de_auction_2 = self.deployer.create_de_auction()[1]

        ts4.core.set_now(SUB_MAKE_BID_TIME)
        de_auction_1.finish_sub_voting(random_guy)
        de_auction_2.finish_sub_voting(random_guy)

        salt = random_salt()  # let if be same for both de auctions
        price_1 = int(0.37 * ts4.GRAM)
        price_2 = int(0.38 * ts4.GRAM)
        bid_hash_1 = de_auction_1.calc_bid_hash(price_1, salt)
        bid_hash_2 = de_auction_2.calc_bid_hash(price_2, salt)
        de_auction_1.make_bid(bid_hash_1)
        de_auction_2.make_bid(bid_hash_2)

        ts4.core.set_now(CONFIRM_TIME)
        de_auction_1.confirm_bid(price_1, salt)
        de_auction_2.confirm_bid(price_2, salt)

        ts4.core.set_now(FINISH_TIME)
        self.auction.finish(random_guy)
        de_auction_1.ping_auction_finish(random_guy)

        self.assertEqual(de_auction_1.call_responsible('getPhase'), DePhase.LOSE, 'Wrong phase')
        self.assertEqual(de_auction_2.call_responsible('getPhase'), DePhase.WIN, 'Wrong phase')
        self.assertEqual(self.auction.call_responsible('getWinner')['owner'], de_auction_2.address, 'Wrong winner')

        # winner gets back difference between first and second bid
        total_stake_2 = de_auction_2.call_responsible('getStakes')[0]
        amount_2 = total_stake_2 // price_2
        expected_return_value = total_stake_2 - price_1 * amount_2
        return_value = de_auction_2.call_responsible('getDistribution')[0]
        self.assertEqual(return_value, expected_return_value, 'Wrong return value')

    def test_slash_claims(self):
        bidder_1 = self.deployer.create_de_bidder(100 * ts4.GRAM, price=None)
        bidder_2 = self.deployer.create_de_bidder(200 * ts4.GRAM, price=None)
        bidder_1.stake()
        bidder_2.stake()
        ts4.core.set_now(CONFIRM_TIME)
        slasher = self.deployer.create_wallet()
        self.de_auction.slash(slasher)
        self._check_phase(DePhase.SLASHED)

        # aggregator gets nothing
        balance_before = self.aggregator.balance
        stake_before = self._de_participant_stake(self.aggregator_de_participant)
        self.assertEqual(stake_before, DEFAULT_AGGREGATOR_VALUE, 'Wrong stake')
        self.aggregator_de_participant.claim(self.de_auction.address)
        balance_after = self.aggregator.balance
        stake_after = self._de_participant_stake(self.aggregator_de_participant)
        self.assertEqual(stake_after, 0, 'Wrong stake')
        self.assertEqual(balance_before, balance_after, 'Wrong balance')

        # bidders get their stake AND part of aggregator stake
        total_value = bidder_1.value + bidder_2.value
        expected_bidder_1_reward = bidder_1.value + DEFAULT_AGGREGATOR_VALUE * bidder_1.value // total_value
        expected_bidder_2_reward = bidder_2.value + DEFAULT_AGGREGATOR_VALUE * bidder_2.value // total_value
        bidder_1_balance_before = bidder_1.wallet.balance
        bidder_2_balance_before = bidder_2.wallet.balance
        bidder_1.claim()
        bidder_2.claim()
        self._check_balance(bidder_1.wallet, bidder_1_balance_before + expected_bidder_1_reward)
        self._check_balance(bidder_2.wallet, bidder_2_balance_before + expected_bidder_2_reward)

    def test_slash_fair_aggregator(self):
        self._win_auction()
        slasher = self.deployer.create_wallet()
        self.de_auction.slash(slasher, Options(1, expect_ec=4002))

    def test_slash_forget_make_bid(self):
        ts4.core.set_now(CONFIRM_TIME)
        slasher = self.deployer.create_wallet()
        self.de_auction.slash(slasher)
        self._check_phase(DePhase.SLASHED)

    def test_slash_forget_confirm_bid(self):
        ts4.core.set_now(SUB_MAKE_BID_TIME)
        slasher = self.deployer.create_wallet()
        self.de_auction.finish_sub_voting(slasher)
        self.de_auction.make_bid(hash=1010101)
        self.de_auction.slash(slasher, Options(1, expect_ec=4002))  # aggregator is fair now
        self._check_phase(DePhase.BID_MADE)

        ts4.core.set_now(FINISH_TIME)
        self.de_auction.slash(slasher)  # aggregator is not fair now
        self._check_phase(DePhase.SLASHED)

    def _win_auction(self) -> list:
        bidders = self._prepare_bidders()
        price = int(0.36 * ts4.GRAM)
        salt = random_salt()
        bid_hash = self.de_auction.calc_bid_hash(price, salt)
        self.de_auction.make_bid(bid_hash)

        ts4.core.set_now(CONFIRM_TIME)
        self.de_auction.confirm_bid(price, salt)

        ts4.core.set_now(FINISH_TIME)
        random_guy = self.deployer.create_wallet()
        self.auction.finish(random_guy)
        return bidders

    def _prepare_bidders(self) -> list:
        # calculate price only for (0, 4, 5) bidders
        bidders = [
            self.deployer.create_de_bidder(150 * ts4.GRAM, price=int(0.36 * ts4.GRAM)),  # ok, but stake will be -50
            self.deployer.create_de_bidder(200 * ts4.GRAM, price=int(0.5 * ts4.GRAM)),  # price out of range, skip
            self.deployer.create_de_bidder(300 * ts4.GRAM, price=None),  # no price, skip
            self.deployer.create_de_bidder(70 * ts4.GRAM, price=int(0.37 * ts4.GRAM)),  # ok
            self.deployer.create_de_bidder(80 * ts4.GRAM, price=int(0.38 * ts4.GRAM)),  # ok
            self.deployer.create_de_bidder(900 * ts4.GRAM, price=int(0.39 * ts4.GRAM)),  # forget to confirm
        ]
        for bidder in bidders:
            bidder.stake()
        bidders[0].remove_stake(50 * ts4.GRAM)
        ts4.core.set_now(SUB_CONFIRM_TIME)
        for i in (0, 1, 3, 4):
            bidders[i].confirm_price()
        ts4.core.set_now(SUB_MAKE_BID_TIME)
        random_guy = self.deployer.create_wallet()
        self.de_auction.finish_sub_voting(random_guy)
        return bidders

    def _de_participant_stake(self, de_participant: DeParticipant) -> int:
        return de_participant.call_responsible('getDeAuctionData', {
            'deAuction': self.de_auction.address
        })[1]

    def _check_phase(self, expected: DePhase):
        self.assertEqual(self.de_auction.call_responsible('getPhase'), expected.value, 'Wrong phase')

    def _check_balance(self, wallet: Wallet, expected: int):
        self.assertEqual(
            wallet.balance, expected, f'Wrong balance, actual={wallet.balance / 1e9}, expected={expected / 1e9}'
        )
