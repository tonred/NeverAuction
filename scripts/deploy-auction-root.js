const {
  logContract,
  logger
} = require('./utils');

const DAYS = 60 * 60 * 24;


const main = async () => {
  const deAuctionContract = 'DeAuctionTIP3';
  // const deAuctionContract = 'DeAuctionECC';
  const [keyPair] = await locklift.keys.getKeyPairs();
  const tempElector = await deployAccount(keyPair, 1);
  const Platform = await locklift.factory.getContract('Platform');
  const Auction = await locklift.factory.getContract('Auction');
  const DeAuction = await locklift.factory.getContract(deAuctionContract);
  const DeParticipant = await locklift.factory.getContract('DeParticipant');
  const Bid = await locklift.factory.getContract('Bid');
  const AuctionRoot = await locklift.factory.getContract('AuctionRoot');

  logger.log('Deploying Auction Root');
  let auctionRoot = await locklift.giver.deployContract({
    contract: AuctionRoot,
    constructorParams: {
      elector: tempElector.address,
      auctionConfig: {
        fee: 2e9,
        deposit: 2e9,
        openDuration: 60,         // 7 days
        deBidDuration: 60,        // 2 days
        confirmDuration: 60,      // 2 days
        bidCode: Bid.code,
      },
      deAuctionGlobalConfig: {
        subOpenDuration: 30,      // 1 days
        subConfirmDuration: 30,   // 1 days
        makeBidDuration: 30,      // 1 days
        initDetails: 'te6ccgEBAQEAKAAASxYPpw2AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQ',  // todo python script for encoding
      },
    },
    initParams: {
      // _randomNonce: 0,
    },
    keyPair
  }, locklift.utils.convertCrystal(5, 'nano'));

  logger.log(`Installing codes`);
  await tempElector.runTarget({
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

  logger.log(`Transferring elector`);
  await tempElector.runTarget({
    contract: auctionRoot,
    method: 'changeElector',
    params: {
      elector: '0:fa94171cb0565789224814561cc558e59315971ee9d03085de3dcb5f8b94d95e',
    },
    value: locklift.utils.convertCrystal(0.3, 'nano')
  });

  await logContract(auctionRoot);
};

const deployAccount = async function (key, value) {
  const Account = await locklift.factory.getAccount('Wallet');
  let account = await locklift.giver.deployContract({
    contract: Account,
    constructorParams: {},
    keyPair: key
  }, locklift.utils.convertCrystal(value, 'nano'));
  account.setKeyPair(key);
  account.afterRun = afterRun;
  return account;
}

const afterRun = async (tx) => {
  await new Promise(resolve => setTimeout(resolve, 2000));
};


main()
  .then(() => process.exit(0))
  .catch(e => {
    console.log(e);
    process.exit(1);
  });
