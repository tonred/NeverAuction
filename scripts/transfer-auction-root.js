const {
  logger,
  Migration,
  afterRun,
} = require('./utils');


const main = async () => {
  let newOwner = process.argv[process.argv.length - 1];
  if (!newOwner.startsWith('0:') && newOwner.length !== 66) {
    console.log('Wrong address');
    return;
  }

  const migration = new Migration();

  const [keyPair] = await locklift.keys.getKeyPairs();
  const tempAdmin = migration.load(await locklift.factory.getAccount('Wallet'), 'Account');
  tempAdmin.setKeyPair(keyPair);
  tempAdmin.afterRun = afterRun;

  const neverElector = migration.load(
      await locklift.factory.getAccount('NeverElectorAuction'), 'NeverElector'
  );

  logger.log(`Transferring Auction Root to ` + newOwner);
  await neverElector.run({
    method: 'transferAuctionRoot',
    params: {
      newOwner: newOwner,
    },
    keyPair: keyPair,
  });
}


main()
  .then(() => process.exit(0))
  .catch(e => {
    console.log(e);
    process.exit(1);
  });
