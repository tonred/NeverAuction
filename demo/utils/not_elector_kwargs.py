import json

with open('migration-log.json', 'r') as file:
    migration = json.load(file)
elector_kwargs = json.dumps({
    'auctionRoot': migration['AuctionRoot']['address'],
    'neverRoot': migration['NeverRoot']['address'],
})
print(elector_kwargs)
