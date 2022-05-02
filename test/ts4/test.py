from tonos_ts4 import ts4

from helpers.deployer import Deployer

deployer = Deployer()
auction_root = deployer.auction_root

owner = deployer.create_wallet()
de_participant = auction_root.create_de_participant(owner)
print(de_participant.calc_price_hash(1, 1))
