const {
  logContract,
  logger
} = require('./utils');

const DAYS = 60 * 60 * 24;


const main = async () => {
  const [keyPair] = await locklift.keys.getKeyPairs();
  const AuctionRoot = await locklift.factory.getAccount('AuctionRoot');
  const Bid = await locklift.factory.getContract('Bid');

  logger.log('Deploying Auction Root');
  let auctionRoot = await locklift.giver.deployContract({
    contract: AuctionRoot,
    constructorParams: {
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
      _elector: '0:0000000000000000000000000000000000000000000000000000000000000000',
    },
    keyPair
  }, locklift.utils.convertCrystal(5, 'nano'));
  await logContract(auctionRoot);
};


main()
  .then(() => process.exit(0))
  .catch(e => {
    console.log(e);
    process.exit(1);
  });
