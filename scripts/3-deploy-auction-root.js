const {
  logContract,
  logger,
  Migration,
  afterRun,
} = require('./utils');
const prompt = require('prompt-sync')();

const DAYS = 60 * 60 * 24;


const main = async () => {
  const migration = new Migration();

  const [keyPair] = await locklift.keys.getKeyPairs();
  const tempAdmin = migration.load(await locklift.factory.getAccount('Wallet'), 'Account');
  tempAdmin.setKeyPair(keyPair);
  tempAdmin.afterRun = afterRun;
  const neverRoot = migration.load(await locklift.factory.getAccount('TestNeverRoot'), 'NeverRoot');

  const deAuctionContract = 'DeAuctionTIP3';
  const Platform = await locklift.factory.getContract('Platform');
  const Auction = await locklift.factory.getContract('Auction');
  const DeAuction = await locklift.factory.getContract(deAuctionContract);
  const DeParticipant = await locklift.factory.getContract('DeParticipant');
  const Bid = await locklift.factory.getContract('Bid');
  const AuctionRoot = await locklift.factory.getContract('AuctionRoot');

  // For TIP3 store only `neverRoot` in init details
  let encoded = await locklift.ton.client.abi.encode_boc({
    params: [{
      name: 'neverRoot',
      type: 'address',
    }],
    data: {
      'neverRoot': neverRoot.address
    }
  });
  let initDetails = encoded.boc;

  logger.log('Deploying Auction Root');
  let auctionRoot = await locklift.giver.deployContract({
    contract: AuctionRoot,
    constructorParams: {
      elector: tempAdmin.address,
      auctionConfig: {
        fee: 1e9,                 // 1e9
        deposit: 2e9,             // 1000e9
        openDuration: 120,        // 7 days
        deBidDuration: 120,       // 2 days
        confirmDuration: 120,     // 2 days
        bidCode: Bid.code,
      },
      deAuctionGlobalConfig: {
        subOpenDuration: 60,      // 1 days
        subConfirmDuration: 60,   // 1 days
        makeBidDuration: 60,      // 1 days
        initDetails: initDetails,
      },
    },
    initParams: {
      // _randomNonce: 0,
    },
    keyPair
  }, locklift.utils.convertCrystal(5, 'nano'));

  logger.log(`Installing codes`);
  await tempAdmin.runTarget({
    contract: auctionRoot,
    method: 'setCodes',
    params: {
      platformCode: Platform.code,
      auctionCode: Auction.code,
      deAuctionCode: DeAuction.code,
      deParticipantCode: DeParticipant.code,
    },
    value: locklift.utils.convertCrystal(0.3, 'nano')
  });

  let userAddress = prompt(
      'Address where transfer never root (ENTER IT ONLY IF YOU WANT TO MANUALLY TEST)\n' +
      'This will break next (4th) step because script will not be able to transfer owner to Never Elector\n' +
      'Address (or just enter to skip): '
  );
  if (userAddress) {
    logger.log(`Transferring elector`);
    await tempAdmin.runTarget({
      contract: auctionRoot,
      method: 'changeElector',
      params: {
        elector: userAddress,
      },
      value: locklift.utils.convertCrystal(0.3, 'nano')
    });
  }

  await logContract(auctionRoot);
  migration.store(auctionRoot, `AuctionRoot`);
};


main()
  .then(() => process.exit(0))
  .catch(e => {
    console.log(e);
    process.exit(1);
  });
