import json
import subprocess

with open('off-chain/config.json', 'r') as file:
    config = json.load(file)
    not_elector = config['not_elector']['address']

subprocess.call(f'npm run transfer-auction-root {not_elector}', shell=True)
