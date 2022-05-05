const {
  logContract,
  logger,
  Migration,
  afterRun,
} = require('./utils');

// from not_oracle `generate_config.py`
const SIGN_UP_START_TIME = Date.now();
const SIGN_UP_DURATION = 10;
const VALIDATION_START_TIME = Date.now() + 20;
const VALIDATION_DURATION = 40;


const main = async () => {
  const migration = new Migration();

  const [keyPair] = await locklift.keys.getKeyPairs();
  const tempAdmin = migration.load(await locklift.factory.getAccount('Wallet'), 'Account');
  tempAdmin.setKeyPair(keyPair);
  tempAdmin.afterRun = afterRun;

  const auctionRoot = migration.load(await locklift.factory.getAccount('AuctionRoot'), 'AuctionRoot');
  const neverRoot = migration.load(await locklift.factory.getAccount('TestNeverRoot'), 'NeverRoot');
  const NeverElector = await locklift.factory.getContract('NeverElectorAuction');

  logger.log('Deploying Never Elector');
  let neverElector = await locklift.giver.deployContract({
    contract: NeverElector,
    constructorParams: {
      signUpStageBeginningArg: SIGN_UP_START_TIME,
      signUpStageDurationArg: SIGN_UP_DURATION,
      validationStageBeginningArg: VALIDATION_START_TIME,
      validationStageDurationArg: VALIDATION_DURATION,
      auctionRoot: auctionRoot.address,
      neverRoot: neverRoot.address,
    },
    initParams: {
      // _randomNonce: 0,
    },
    keyPair
  }, locklift.utils.convertCrystal(15, 'nano'));

  logger.log(`Transferring Auction Root`);
  await tempAdmin.runTarget({
    contract: auctionRoot,
    method: 'changeElector',
    params: {
      elector: neverElector.address,
    },
    value: locklift.utils.convertCrystal(0.3, 'nano')
  });

  await logContract(neverElector);
  migration.store(neverElector, `NeverElector`);
}


main()
  .then(() => process.exit(0))
  .catch(e => {
    console.log(e);
    process.exit(1);
  });
