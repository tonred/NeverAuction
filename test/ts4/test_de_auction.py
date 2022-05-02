import unittest

from helpers.deployer import Deployer


class TestDeAuction(unittest.TestCase):

    def setUp(self):
        self.deployer = Deployer(now=0)
        self.auction = self.deployer.auction
        self.de_auction = self.deployer.de_auction
        self.aggregator = self.deployer.aggregator
