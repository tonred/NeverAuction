import json
import subprocess

with open('not_oracle/src/off-chain/config.json', 'r') as file:
    config = json.load(file)
    network = config['network']

with open('migration-log.json', 'r') as file:
    migration = json.load(file)
    auction_root = migration['AuctionRoot']['address']

subprocess.call(f'''
tonos-cli config --url {network}
tonos-cli run {auction_root} _auction '{{}}' --abi build/AuctionRoot.abi.json
''', shell=True)
print(network, auction_root)
