const {
  logContract,
  logger,
  Migration,
  afterRun,
} = require('./utils');


const main = async () => {
  const migration = new Migration();

  const [keyPair] = await locklift.keys.getKeyPairs();
  const tempAdmin = migration.load(await locklift.factory.getAccount('Wallet'), 'Account');
  tempAdmin.setKeyPair(keyPair);
  tempAdmin.afterRun = afterRun;

  const NeverWalletPlatform = await locklift.factory.getContract('TestNeverWalletPlatform');
  const NeverWallet = await locklift.factory.getContract('TestNeverWallet');
  const NeverRoot = await locklift.factory.getContract('TestNeverRoot');
  let addressZero = '0:0000000000000000000000000000000000000000000000000000000000000000';

  logger.log('Deploying Never Root');
  let neverRoot = await locklift.giver.deployContract({
    contract: NeverRoot,
    constructorParams: {
      initialSupplyTo: addressZero,
      initialSupply: 0,
      deployWalletValue: 0.2 * 1e9,
      mintDisabled: false,
      burnByRootDisabled: true,
      burnPaused: false,
      remainingGasTo: addressZero,
      owner: tempAdmin.address,
    },
    initParams: {
      randomNonce_: Date.now(),
      name_: 'Never',
      symbol_: 'NEVER',
      decimals_: 9,
      rootOwner_: addressZero,
      walletCode_: NeverWallet.code,
      deployer_: addressZero,
      platformCode_: NeverWalletPlatform.code,
    },
    keyPair
  }, locklift.utils.convertCrystal(3, 'nano'));
  await logContract(neverRoot);
  migration.store(neverRoot, `NeverRoot`);
};


main()
  .then(() => process.exit(0))
  .catch(e => {
    console.log(e);
    process.exit(1);
  });
