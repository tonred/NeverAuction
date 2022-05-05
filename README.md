# Never Auction

Project Github: https://github.com/tonred/NeverAuction

DevNet Auction Root: `0:d37297b1eba504c3ec3c9d3c4fab7c3d4eb5152e39e380d727705c20fa8a2ff3`

TG: @Abionics, @get_username

## Key features:
* Really blind Vickrey auction
* DeAuction for group bid with interesting concept
* No mappings, infinity amount of bids and DeParticipants
* Well tested, 30 `ts4` tests
* A lot of custom configurations
* Browser viewer for deployed auctions

## Requirements:
* [locklift](https://www.npmjs.com/package/locklift) `1.5.3`
* [everdev](https://github.com/tonlabs/everdev) with compiler=`0.59.4`, linker=`0.15.24`
* python `>=3.8`
* nodejs

## Setup environment
1) Setup `locklift.config.js` and `.env` for templates
2) Create and activate python venv
3) Install npm `npm install`
4) Run setup `npm run setup`
5) Read steps below

## Build
```shell
npm run build
```
// todo

Read technical description below

## Test
```shell
npm run test
```

There are 30 different test cases. They cover both Auction and DeAuction usage.
Set env variable `TS4_VERBOSE=true` in order to see flow of method calls.
In case of trouble with `npm`, just go to `test/ts4` folder and call `run_tests.sh` manually

![test1](docs/test1.png)
![test2](docs/test2.png)

## Deployment
```shell
npm run 1-deploy-account.js
npm run 2-deploy-never-root.js
npm run 3-deploy-auction-root.js
npm run 4-deploy-never-elector.js  # (optionally)
```
Don't forget to set up network url in `locklift.config.js` before deployment.
In step **#3** you can set Auction Root owner (elector) to your wallet address
in order to create and test auctions on your own way

## Technical description

### Auction
Source code: [Auction.sol](contracts/Auction.sol)

Auction is created by Auction Root. It has some configurable values:
fee, deposit, time of each phase and bid code. These values are set up
can in Auction Root and can be changed  by Elector

Each auction has 5 phases (see [Phase.sol](contracts/structures/Phase.sol)):
1) `Open` - in this phase anyone can make and remove his blind bid. To do this,
user must generate random salt, locally encode your bid via `calcBidHash` method and 
then send this hash to `makeBid`. This bid hash contains from price for 1 token,
amount to buy, sender address and random salt. User also must send a deposit value
in order to prevent spamming with bids without revealing them. User also can remove their bid
and get deposit back in this phase via method `removeBid`
2) `DeBid` - this phase is used for DeAuction bidding, we will back to it bellow.
Only DeAuctions can bid in this phase
3) `Confirm` - users must confirm their bid by sending price, amount and salt to
`confirmBid` method. If all values are correct, then bid is counted and user gets back
his deposit (minus some small fee for gas)
4) `Finish` - this phase means than all bids are done (or time passed) and auction can be finished.
To finish auction, anyone can call `finish` method in this phase.
5) `Done` - used after finishing auction, means that it is completely ended

As mentioned above, some bid `deposit` used in order to prevent spamming with bids without
revealing them. This deposit will be instantly returned after bid confirmation.
Each bid is a separate contract [Bid.sol](contracts/Bid.sol).

**Make bid:**
```mermaid
sequenceDiagram
    autonumber

    external -) 0fa94171cb0565789224814561cc558e59315971ee9d03085de3dcb5f8b94d95e: sendTransaction
    0fa94171cb0565789224814561cc558e59315971ee9d03085de3dcb5f8b94d95e ->> 040e454e24d436557a1ab10ffb7305be07ad067eab25f0fbda58a500c6abd3c8e: makeBid
    040e454e24d436557a1ab10ffb7305be07ad067eab25f0fbda58a500c6abd3c8e ->> 0f8826d6816f436d77aad381979dafdf1022e3d8c04f6c1d35cda28023f4ab2a7: constructor
    040e454e24d436557a1ab10ffb7305be07ad067eab25f0fbda58a500c6abd3c8e --) external: MakeBid
    040e454e24d436557a1ab10ffb7305be07ad067eab25f0fbda58a500c6abd3c8e ->> 0fa94171cb0565789224814561cc558e59315971ee9d03085de3dcb5f8b94d95e: onMakeBid

    participant external as #60;external#62;
    participant 040e454e24d436557a1ab10ffb7305be07ad067eab25f0fbda58a500c6abd3c8e as Auction
    link 040e454e24d436557a1ab10ffb7305be07ad067eab25f0fbda58a500c6abd3c8e: 0:40e454e24d436557a1ab10ffb7305be07ad067eab25f0fbda58a500c6abd3c8e @
    link 040e454e24d436557a1ab10ffb7305be07ad067eab25f0fbda58a500c6abd3c8e: delta: 1.4639706 @
    link 040e454e24d436557a1ab10ffb7305be07ad067eab25f0fbda58a500c6abd3c8e: #64;ever.live @ https://net.ever.live/accounts/accountDetails?id=0:40e454e24d436557a1ab10ffb7305be07ad067eab25f0fbda58a500c6abd3c8e
    link 040e454e24d436557a1ab10ffb7305be07ad067eab25f0fbda58a500c6abd3c8e: #64;tonscan.io @ https://dev.tonscan.io/accounts/0:40e454e24d436557a1ab10ffb7305be07ad067eab25f0fbda58a500c6abd3c8e
    participant 0fa94171cb0565789224814561cc558e59315971ee9d03085de3dcb5f8b94d95e as @A
    link 0fa94171cb0565789224814561cc558e59315971ee9d03085de3dcb5f8b94d95e: 0:fa94171cb0565789224814561cc558e59315971ee9d03085de3dcb5f8b94d95e @
    link 0fa94171cb0565789224814561cc558e59315971ee9d03085de3dcb5f8b94d95e: delta: -2.014747097 @
    link 0fa94171cb0565789224814561cc558e59315971ee9d03085de3dcb5f8b94d95e: #64;ever.live @ https://net.ever.live/accounts/accountDetails?id=0:fa94171cb0565789224814561cc558e59315971ee9d03085de3dcb5f8b94d95e
    link 0fa94171cb0565789224814561cc558e59315971ee9d03085de3dcb5f8b94d95e: #64;tonscan.io @ https://dev.tonscan.io/accounts/0:fa94171cb0565789224814561cc558e59315971ee9d03085de3dcb5f8b94d95e
    participant 0f8826d6816f436d77aad381979dafdf1022e3d8c04f6c1d35cda28023f4ab2a7 as Bid
    link 0f8826d6816f436d77aad381979dafdf1022e3d8c04f6c1d35cda28023f4ab2a7: 0:f8826d6816f436d77aad381979dafdf1022e3d8c04f6c1d35cda28023f4ab2a7 @
    link 0f8826d6816f436d77aad381979dafdf1022e3d8c04f6c1d35cda28023f4ab2a7: delta: 0.494428000 @
    link 0f8826d6816f436d77aad381979dafdf1022e3d8c04f6c1d35cda28023f4ab2a7: #64;ever.live @ https://net.ever.live/accounts/accountDetails?id=0:f8826d6816f436d77aad381979dafdf1022e3d8c04f6c1d35cda28023f4ab2a7
    link 0f8826d6816f436d77aad381979dafdf1022e3d8c04f6c1d35cda28023f4ab2a7: #64;tonscan.io @ https://dev.tonscan.io/accounts/0:f8826d6816f436d77aad381979dafdf1022e3d8c04f6c1d35cda28023f4ab2a7
```

**Remove bid:**
```mermaid
sequenceDiagram
    autonumber

    external -) 0fa94171cb0565789224814561cc558e59315971ee9d03085de3dcb5f8b94d95e: sendTransaction
    0fa94171cb0565789224814561cc558e59315971ee9d03085de3dcb5f8b94d95e ->> 064017f20f04c8d587ab72ac893e6a15ba94e990410b99a94103c2ca018e536ee: removeBid
    064017f20f04c8d587ab72ac893e6a15ba94e990410b99a94103c2ca018e536ee ->> 0edbe68fc206aeb9e7385e3ed8eb04c845264aac54155c65c0f6402f7f400fb13: remove
    0edbe68fc206aeb9e7385e3ed8eb04c845264aac54155c65c0f6402f7f400fb13 ->> 064017f20f04c8d587ab72ac893e6a15ba94e990410b99a94103c2ca018e536ee: onRemoveBid
    064017f20f04c8d587ab72ac893e6a15ba94e990410b99a94103c2ca018e536ee ->> 0fa94171cb0565789224814561cc558e59315971ee9d03085de3dcb5f8b94d95e: onRemoveBid
    064017f20f04c8d587ab72ac893e6a15ba94e990410b99a94103c2ca018e536ee --) external: RemoveBid
    064017f20f04c8d587ab72ac893e6a15ba94e990410b99a94103c2ca018e536ee ->> 0fa94171cb0565789224814561cc558e59315971ee9d03085de3dcb5f8b94d95e: #60;transfer#62;

    participant external as #60;external#62;
    participant 0edbe68fc206aeb9e7385e3ed8eb04c845264aac54155c65c0f6402f7f400fb13 as Bid
    link 0edbe68fc206aeb9e7385e3ed8eb04c845264aac54155c65c0f6402f7f400fb13: 0:edbe68fc206aeb9e7385e3ed8eb04c845264aac54155c65c0f6402f7f400fb13 @
    link 0edbe68fc206aeb9e7385e3ed8eb04c845264aac54155c65c0f6402f7f400fb13: delta: -0.494428000 @
    link 0edbe68fc206aeb9e7385e3ed8eb04c845264aac54155c65c0f6402f7f400fb13: #64;ever.live @ https://net.ever.live/accounts/accountDetails?id=0:edbe68fc206aeb9e7385e3ed8eb04c845264aac54155c65c0f6402f7f400fb13
    link 0edbe68fc206aeb9e7385e3ed8eb04c845264aac54155c65c0f6402f7f400fb13: #64;tonscan.io @ https://dev.tonscan.io/accounts/0:edbe68fc206aeb9e7385e3ed8eb04c845264aac54155c65c0f6402f7f400fb13
    participant 0fa94171cb0565789224814561cc558e59315971ee9d03085de3dcb5f8b94d95e as @A
    link 0fa94171cb0565789224814561cc558e59315971ee9d03085de3dcb5f8b94d95e: 0:fa94171cb0565789224814561cc558e59315971ee9d03085de3dcb5f8b94d95e @
    link 0fa94171cb0565789224814561cc558e59315971ee9d03085de3dcb5f8b94d95e: delta: 0.664403945 @
    link 0fa94171cb0565789224814561cc558e59315971ee9d03085de3dcb5f8b94d95e: #64;ever.live @ https://net.ever.live/accounts/accountDetails?id=0:fa94171cb0565789224814561cc558e59315971ee9d03085de3dcb5f8b94d95e
    link 0fa94171cb0565789224814561cc558e59315971ee9d03085de3dcb5f8b94d95e: #64;tonscan.io @ https://dev.tonscan.io/accounts/0:fa94171cb0565789224814561cc558e59315971ee9d03085de3dcb5f8b94d95e
    participant 064017f20f04c8d587ab72ac893e6a15ba94e990410b99a94103c2ca018e536ee as Auction
    link 064017f20f04c8d587ab72ac893e6a15ba94e990410b99a94103c2ca018e536ee: 0:64017f20f04c8d587ab72ac893e6a15ba94e990410b99a94103c2ca018e536ee @
    link 064017f20f04c8d587ab72ac893e6a15ba94e990410b99a94103c2ca018e536ee: delta: -0.231491303 @
    link 064017f20f04c8d587ab72ac893e6a15ba94e990410b99a94103c2ca018e536ee: #64;ever.live @ https://net.ever.live/accounts/accountDetails?id=0:64017f20f04c8d587ab72ac893e6a15ba94e990410b99a94103c2ca018e536ee
    link 064017f20f04c8d587ab72ac893e6a15ba94e990410b99a94103c2ca018e536ee: #64;tonscan.io @ https://dev.tonscan.io/accounts/0:64017f20f04c8d587ab72ac893e6a15ba94e990410b99a94103c2ca018e536ee
```

**Confirm bid:**
```mermaid
sequenceDiagram
    autonumber

    external -) 0fa94171cb0565789224814561cc558e59315971ee9d03085de3dcb5f8b94d95e: sendTransaction
    0fa94171cb0565789224814561cc558e59315971ee9d03085de3dcb5f8b94d95e ->> 040e454e24d436557a1ab10ffb7305be07ad067eab25f0fbda58a500c6abd3c8e: confirmBid
    040e454e24d436557a1ab10ffb7305be07ad067eab25f0fbda58a500c6abd3c8e ->> 0f8826d6816f436d77aad381979dafdf1022e3d8c04f6c1d35cda28023f4ab2a7: confirm
    0f8826d6816f436d77aad381979dafdf1022e3d8c04f6c1d35cda28023f4ab2a7 ->> 040e454e24d436557a1ab10ffb7305be07ad067eab25f0fbda58a500c6abd3c8e: onConfirmBid
    040e454e24d436557a1ab10ffb7305be07ad067eab25f0fbda58a500c6abd3c8e ->> 0fa94171cb0565789224814561cc558e59315971ee9d03085de3dcb5f8b94d95e: onConfirmBid
    040e454e24d436557a1ab10ffb7305be07ad067eab25f0fbda58a500c6abd3c8e --) external: ConfirmBid

    participant external as #60;external#62;
    participant 0fa94171cb0565789224814561cc558e59315971ee9d03085de3dcb5f8b94d95e as @A
    link 0fa94171cb0565789224814561cc558e59315971ee9d03085de3dcb5f8b94d95e: 0:fa94171cb0565789224814561cc558e59315971ee9d03085de3dcb5f8b94d95e @
    link 0fa94171cb0565789224814561cc558e59315971ee9d03085de3dcb5f8b94d95e: delta: 0.985015732 @
    link 0fa94171cb0565789224814561cc558e59315971ee9d03085de3dcb5f8b94d95e: #64;ever.live @ https://net.ever.live/accounts/accountDetails?id=0:fa94171cb0565789224814561cc558e59315971ee9d03085de3dcb5f8b94d95e
    link 0fa94171cb0565789224814561cc558e59315971ee9d03085de3dcb5f8b94d95e: #64;tonscan.io @ https://dev.tonscan.io/accounts/0:fa94171cb0565789224814561cc558e59315971ee9d03085de3dcb5f8b94d95e
    participant 040e454e24d436557a1ab10ffb7305be07ad067eab25f0fbda58a500c6abd3c8e as Auction
    link 040e454e24d436557a1ab10ffb7305be07ad067eab25f0fbda58a500c6abd3c8e: 0:40e454e24d436557a1ab10ffb7305be07ad067eab25f0fbda58a500c6abd3c8e @
    link 040e454e24d436557a1ab10ffb7305be07ad067eab25f0fbda58a500c6abd3c8e: delta: -0.558053367 @
    link 040e454e24d436557a1ab10ffb7305be07ad067eab25f0fbda58a500c6abd3c8e: #64;ever.live @ https://net.ever.live/accounts/accountDetails?id=0:40e454e24d436557a1ab10ffb7305be07ad067eab25f0fbda58a500c6abd3c8e
    link 040e454e24d436557a1ab10ffb7305be07ad067eab25f0fbda58a500c6abd3c8e: #64;tonscan.io @ https://dev.tonscan.io/accounts/0:40e454e24d436557a1ab10ffb7305be07ad067eab25f0fbda58a500c6abd3c8e
    participant 0f8826d6816f436d77aad381979dafdf1022e3d8c04f6c1d35cda28023f4ab2a7 as Bid
    link 0f8826d6816f436d77aad381979dafdf1022e3d8c04f6c1d35cda28023f4ab2a7: 0:f8826d6816f436d77aad381979dafdf1022e3d8c04f6c1d35cda28023f4ab2a7 @
    link 0f8826d6816f436d77aad381979dafdf1022e3d8c04f6c1d35cda28023f4ab2a7: delta: -0.494428000 @
    link 0f8826d6816f436d77aad381979dafdf1022e3d8c04f6c1d35cda28023f4ab2a7: #64;ever.live @ https://net.ever.live/accounts/accountDetails?id=0:f8826d6816f436d77aad381979dafdf1022e3d8c04f6c1d35cda28023f4ab2a7
    link 0f8826d6816f436d77aad381979dafdf1022e3d8c04f6c1d35cda28023f4ab2a7: #64;tonscan.io @ https://dev.tonscan.io/accounts/0:f8826d6816f436d77aad381979dafdf1022e3d8c04f6c1d35cda28023f4ab2a7
```

**Finish auction:**
```mermaid
sequenceDiagram
    autonumber

    external -) 0fa94171cb0565789224814561cc558e59315971ee9d03085de3dcb5f8b94d95e: sendTransaction
    0fa94171cb0565789224814561cc558e59315971ee9d03085de3dcb5f8b94d95e ->> 040e454e24d436557a1ab10ffb7305be07ad067eab25f0fbda58a500c6abd3c8e: finish
    040e454e24d436557a1ab10ffb7305be07ad067eab25f0fbda58a500c6abd3c8e ->> 0fa94171cb0565789224814561cc558e59315971ee9d03085de3dcb5f8b94d95e: onWin
    040e454e24d436557a1ab10ffb7305be07ad067eab25f0fbda58a500c6abd3c8e --) external: Finish
    040e454e24d436557a1ab10ffb7305be07ad067eab25f0fbda58a500c6abd3c8e ->> 0c86dbf16cf391b6dc99948adc97b6693af6635b7247fc74678fb43dcd2e6c939: onFinish
    0c86dbf16cf391b6dc99948adc97b6693af6635b7247fc74678fb43dcd2e6c939 --) external: Finish
    0c86dbf16cf391b6dc99948adc97b6693af6635b7247fc74678fb43dcd2e6c939 ->> 0fa94171cb0565789224814561cc558e59315971ee9d03085de3dcb5f8b94d95e: onAuctionFinish

    participant external as #60;external#62;
    participant 040e454e24d436557a1ab10ffb7305be07ad067eab25f0fbda58a500c6abd3c8e as Auction
    link 040e454e24d436557a1ab10ffb7305be07ad067eab25f0fbda58a500c6abd3c8e: 0:40e454e24d436557a1ab10ffb7305be07ad067eab25f0fbda58a500c6abd3c8e @
    link 040e454e24d436557a1ab10ffb7305be07ad067eab25f0fbda58a500c6abd3c8e: delta: -1.891036233 @
    link 040e454e24d436557a1ab10ffb7305be07ad067eab25f0fbda58a500c6abd3c8e: #64;ever.live @ https://net.ever.live/accounts/accountDetails?id=0:40e454e24d436557a1ab10ffb7305be07ad067eab25f0fbda58a500c6abd3c8e
    link 040e454e24d436557a1ab10ffb7305be07ad067eab25f0fbda58a500c6abd3c8e: #64;tonscan.io @ https://dev.tonscan.io/accounts/0:40e454e24d436557a1ab10ffb7305be07ad067eab25f0fbda58a500c6abd3c8e
    participant 0fa94171cb0565789224814561cc558e59315971ee9d03085de3dcb5f8b94d95e as @A
    link 0fa94171cb0565789224814561cc558e59315971ee9d03085de3dcb5f8b94d95e: 0:fa94171cb0565789224814561cc558e59315971ee9d03085de3dcb5f8b94d95e @
    link 0fa94171cb0565789224814561cc558e59315971ee9d03085de3dcb5f8b94d95e: delta: 1.840140892 @
    link 0fa94171cb0565789224814561cc558e59315971ee9d03085de3dcb5f8b94d95e: #64;ever.live @ https://net.ever.live/accounts/accountDetails?id=0:fa94171cb0565789224814561cc558e59315971ee9d03085de3dcb5f8b94d95e
    link 0fa94171cb0565789224814561cc558e59315971ee9d03085de3dcb5f8b94d95e: #64;tonscan.io @ https://dev.tonscan.io/accounts/0:fa94171cb0565789224814561cc558e59315971ee9d03085de3dcb5f8b94d95e
    participant 0c86dbf16cf391b6dc99948adc97b6693af6635b7247fc74678fb43dcd2e6c939 as AuctionRoot
    link 0c86dbf16cf391b6dc99948adc97b6693af6635b7247fc74678fb43dcd2e6c939: 0:c86dbf16cf391b6dc99948adc97b6693af6635b7247fc74678fb43dcd2e6c939 @
    link 0c86dbf16cf391b6dc99948adc97b6693af6635b7247fc74678fb43dcd2e6c939: delta: -0.001795071 @
    link 0c86dbf16cf391b6dc99948adc97b6693af6635b7247fc74678fb43dcd2e6c939: #64;ever.live @ https://net.ever.live/accounts/accountDetails?id=0:c86dbf16cf391b6dc99948adc97b6693af6635b7247fc74678fb43dcd2e6c939
    link 0c86dbf16cf391b6dc99948adc97b6693af6635b7247fc74678fb43dcd2e6c939: #64;tonscan.io @ https://dev.tonscan.io/accounts/0:c86dbf16cf391b6dc99948adc97b6693af6635b7247fc74678fb43dcd2e6c939
```

<details>
<summary>Click here to see interfaces for diagrams above</summary>

```solidity
function makeBid(uint256 hash) external;
function removeBid(uint256 hash) external view;
function confirmBid(uint128 price, uint128 amount, uint256 salt) external view;
function calcBidHash(uint128 price, uint128 amount, address owner, uint256 salt) external view returns (uint256 hash);
function finish() external;
```

</details>

### DeParticipant
Source code: [DeParticipant.sol](contracts/DeParticipant.sol)

This is a user data for creation and interation with DeAuction.
It is deployed once for each wallet. At has locker in order to prevent
double spending and double bidding. See diagrams in DeAuction section
because DeParticipant are closely related with DeAuction

<details>
<summary>Click here to see main function for DeParticipant</summary>

```solidity
function createDeAuction(string description, PriceRange prices, uint128 deviation, uint128 fee, uint128 value) external view;
function stake(address deAuction, uint128 value, optional(uint256) priceHash) external view;
function removeStake(address deAuction, uint128 value) external view;
function confirmPrice(address deAuction, uint128 price, uint256 salt) external;
function claim(address deAuction) external view;
function calcPriceHash(uint128 price, uint256 salt) external view returns (uint256 hash);
```

</details>

### DeAuction
Source code: [DeAuction.sol](contracts/DeAuction.sol)

Both DeParticipant and DeAuction are created by Auction Root.
Anyone can create DeAuction from DeParticipant if there is active Auction.
Let's call the deployer of DeAuction as **Aggregator** (see [whitepaper](https://firebasestorage.googleapis.com/v0/b/ton-labs.appspot.com/o/documents%2Fapplication%2Fpdf%2F4rdykjz6rxbkk4gmv6k-NOT%20a%20TON%20Binary%20System.pdf?alt=media&token=8fca4969-e2cc-477d-bc80-1456e8107f1b)).
Aggregator can set up some parameters of DeAuction:
1) Price range - **first** interesting concept of DeAuctions. It has predefined price range with
min and max price that it DeParticipant can suggest (read below about consensus) and Aggregator 
must make bid only from this price range
2) Deviation - **second** interesting concept of DeAuctions. It is a percent on which
DeAuction's final price bid can be different from consensus price (read below about consensus)
3) Description - just a text that describe this DeAuction, it plans etc
4) Aggregator fee - just a fee of aggregator from distributed Never value
5) Aggregator stake - initial aggregator value, aggregator can increase it, but not decrease

#### DeAuction consensus
This is a third interesting concept, each DeAuction has a local Vickrey voting. Every DeParticipant
can (but not must) provide a hash of desire price. As mentioned above, this price must be in
DeAuction price range. This local voting starts immediately after DeAuction created, and confirm
phase of this voting starts in one time with `DE_BID` main phase. This means that common users
won't be able to use revealed price in their bids.  Main `DE_BID` phase splits into 2 DeAuction phases. In first one DeParticipants must reveal their
prices (if exist), in second phase Aggregator must make a bid

Consensus price are calculated as average between DeParticipant prices, where each price has
weight of its owner's stake. To be exact, the formula is:

![DeAuction-consensus-formula](docs/DeAuction-consensus-formula.png)

If no one price was confirm, then consensus price is average in possible price range. If someone
doesn't provide a desire price, or forget to confirm, then his price is not included is
average calculation. But his stake is participating and such DeParticipant will get his
reward in case of winning

#### DeAuction phases
DeAuctions can have such phases (let call them DePhase, see [DePhase.sol](contracts/structures/DePhase.sol)):
1) `INITIALIZING` - used when contract is not inited
2) `SUB_OPEN` - it this phase everyone can join and stake. Also, everyone, except the Aggregator,
can remove his stake, partially or fully. All these actions are done via DeParticipant methods
`stake` and `removeStake` (price hash can be calculated via `calcPriceHash` method)
3) `SUB_CONFIRM` - in this phase users that provide price in previous step can confirm it via
`confirmPrice` method in DeParticipant
4) `SUB_FINISH` - this phase means that time for confirming price is passed. Someone should call
`finishSubVoting` in order to calculate consensus price, stop DeAuction if not enough fund and
continue to next phase
5) `WAITING_BID` - this phase means that Aggregator must make a bid. He should locally call
`allowedPrice` to get allowed price range, `calcBidHash` to calculate bid hash and finally
`makeBid` to make bid in main Auction. Don't forget that allowed price is always in
DeAuction price range, and does not differ from the consensus value by more than
`deviation` percents (in other case `calcBidHash` will throw an exception)
6) `BID_MADE` - means that Aggregator made bid, but Aggregator should
track Auction phase in order to don't forget to confirm bid
7) `BID_CONFIRMED` - means that Aggregator confirmed bid (which is so obvious)
8) `WIN` - used when DeAuction won, but Never tokens are not transferred yet
9) `DISTRIBUTION`  - means that never tokens are transferred, everyone can claim them
via `claim` in DeParticipant
10) `LOSE` - means that DeAuction lose (or not enough funds), everyone can claim his stake back
via `claim` in DeParticipant
11) `SLASHED` - used when Aggregator was slashed. Everyone except the Aggregator can get his stake
back via `claim` in DeParticipant, see slashing details below

#### DeAuction slashing
Everyone can locally check if Aggregator must be slashed via `checkAggregator` method.
Slashing is used if Aggregator forget to make bid in until end of `DE_BID` phase, or forget
to confirm bid until end of `CONFIRM` phase. Is this case, anyone can call `slash` method
directly in DeAuction. After slashing, Aggregator lose his stake, and it is distributed
among all DeParticipant proportionately to their stakes. They can claim their stake and
slash reward via `claim` in DeParticipant

### DeParticipant and DeAuction diagrams

**Create DeAuction:**
```mermaid
sequenceDiagram
    autonumber

    external -) 0fa94171cb0565789224814561cc558e59315971ee9d03085de3dcb5f8b94d95e: sendTransaction
    0fa94171cb0565789224814561cc558e59315971ee9d03085de3dcb5f8b94d95e ->> 0b4d8d88307a798d2817ae47ca16166071ad00bf87c8158588af719a3a8a84b25: createDeAuction
    0b4d8d88307a798d2817ae47ca16166071ad00bf87c8158588af719a3a8a84b25 ->> 0fa94171cb0565789224814561cc558e59315971ee9d03085de3dcb5f8b94d95e: #60;transfer#62;
    0b4d8d88307a798d2817ae47ca16166071ad00bf87c8158588af719a3a8a84b25 ->> 0d37297b1eba504c3ec3c9d3c4fab7c3d4eb5152e39e380d727705c20fa8a2ff3: createDeAuction
    0d37297b1eba504c3ec3c9d3c4fab7c3d4eb5152e39e380d727705c20fa8a2ff3 --) external: NewDeAuction
    0d37297b1eba504c3ec3c9d3c4fab7c3d4eb5152e39e380d727705c20fa8a2ff3 ->>+ 0729c0b4f98e6f4191d204069ce5fd0a56b4ca162d3bd29e8bf6489250f1eebab: constructor
    0729c0b4f98e6f4191d204069ce5fd0a56b4ca162d3bd29e8bf6489250f1eebab ->> 073ed104a7397feaf4f4a5f847ebda71691c52fd79b0eb0a177cd4c77de5733f9: getDetails
    073ed104a7397feaf4f4a5f847ebda71691c52fd79b0eb0a177cd4c77de5733f9 ->> 0729c0b4f98e6f4191d204069ce5fd0a56b4ca162d3bd29e8bf6489250f1eebab: onGetDetails
    0729c0b4f98e6f4191d204069ce5fd0a56b4ca162d3bd29e8bf6489250f1eebab ->> 0b4d8d88307a798d2817ae47ca16166071ad00bf87c8158588af719a3a8a84b25: onDeAuctionInit
    0b4d8d88307a798d2817ae47ca16166071ad00bf87c8158588af719a3a8a84b25 --) external: NewDeAuction
    0b4d8d88307a798d2817ae47ca16166071ad00bf87c8158588af719a3a8a84b25 ->> 0fa94171cb0565789224814561cc558e59315971ee9d03085de3dcb5f8b94d95e: onDeAuctionInit
    0729c0b4f98e6f4191d204069ce5fd0a56b4ca162d3bd29e8bf6489250f1eebab ->>- 0cd7a4b9cd73044f33d256367627c393ac5fb170b07d2e45f119e1789b3c0acd9: deployWallet
    0cd7a4b9cd73044f33d256367627c393ac5fb170b07d2e45f119e1789b3c0acd9 ->> 0729c0b4f98e6f4191d204069ce5fd0a56b4ca162d3bd29e8bf6489250f1eebab: onWalletDeployed
    0cd7a4b9cd73044f33d256367627c393ac5fb170b07d2e45f119e1789b3c0acd9 ->> 0d7ebc23e461dffb0ed1c1944c0cfbc96b98c8417dbdccce57f38e4491cfdfd4a: onDeployRetry
    0d7ebc23e461dffb0ed1c1944c0cfbc96b98c8417dbdccce57f38e4491cfdfd4a ->> 0729c0b4f98e6f4191d204069ce5fd0a56b4ca162d3bd29e8bf6489250f1eebab: #60;transfer#62;

    participant external as #60;external#62;
    participant 0d7ebc23e461dffb0ed1c1944c0cfbc96b98c8417dbdccce57f38e4491cfdfd4a as Token Wallet
    link 0d7ebc23e461dffb0ed1c1944c0cfbc96b98c8417dbdccce57f38e4491cfdfd4a: 0:d7ebc23e461dffb0ed1c1944c0cfbc96b98c8417dbdccce57f38e4491cfdfd4a @
    link 0d7ebc23e461dffb0ed1c1944c0cfbc96b98c8417dbdccce57f38e4491cfdfd4a: delta: 0.100000000 @
    link 0d7ebc23e461dffb0ed1c1944c0cfbc96b98c8417dbdccce57f38e4491cfdfd4a: #64;ever.live @ https://net.ever.live/accounts/accountDetails?id=0:d7ebc23e461dffb0ed1c1944c0cfbc96b98c8417dbdccce57f38e4491cfdfd4a
    link 0d7ebc23e461dffb0ed1c1944c0cfbc96b98c8417dbdccce57f38e4491cfdfd4a: #64;tonscan.io @ https://dev.tonscan.io/accounts/0:d7ebc23e461dffb0ed1c1944c0cfbc96b98c8417dbdccce57f38e4491cfdfd4a
    participant 0d37297b1eba504c3ec3c9d3c4fab7c3d4eb5152e39e380d727705c20fa8a2ff3 as AuctionRoot
    link 0d37297b1eba504c3ec3c9d3c4fab7c3d4eb5152e39e380d727705c20fa8a2ff3: 0:d37297b1eba504c3ec3c9d3c4fab7c3d4eb5152e39e380d727705c20fa8a2ff3 @
    link 0d37297b1eba504c3ec3c9d3c4fab7c3d4eb5152e39e380d727705c20fa8a2ff3: delta: -0.001767213 @
    link 0d37297b1eba504c3ec3c9d3c4fab7c3d4eb5152e39e380d727705c20fa8a2ff3: #64;ever.live @ https://net.ever.live/accounts/accountDetails?id=0:d37297b1eba504c3ec3c9d3c4fab7c3d4eb5152e39e380d727705c20fa8a2ff3
    link 0d37297b1eba504c3ec3c9d3c4fab7c3d4eb5152e39e380d727705c20fa8a2ff3: #64;tonscan.io @ https://dev.tonscan.io/accounts/0:d37297b1eba504c3ec3c9d3c4fab7c3d4eb5152e39e380d727705c20fa8a2ff3
    participant 0729c0b4f98e6f4191d204069ce5fd0a56b4ca162d3bd29e8bf6489250f1eebab as DeAuction
    link 0729c0b4f98e6f4191d204069ce5fd0a56b4ca162d3bd29e8bf6489250f1eebab: 0:729c0b4f98e6f4191d204069ce5fd0a56b4ca162d3bd29e8bf6489250f1eebab @
    link 0729c0b4f98e6f4191d204069ce5fd0a56b4ca162d3bd29e8bf6489250f1eebab: delta: 2.130097854 @
    link 0729c0b4f98e6f4191d204069ce5fd0a56b4ca162d3bd29e8bf6489250f1eebab: #64;ever.live @ https://net.ever.live/accounts/accountDetails?id=0:729c0b4f98e6f4191d204069ce5fd0a56b4ca162d3bd29e8bf6489250f1eebab
    link 0729c0b4f98e6f4191d204069ce5fd0a56b4ca162d3bd29e8bf6489250f1eebab: #64;tonscan.io @ https://dev.tonscan.io/accounts/0:729c0b4f98e6f4191d204069ce5fd0a56b4ca162d3bd29e8bf6489250f1eebab
    participant 0b4d8d88307a798d2817ae47ca16166071ad00bf87c8158588af719a3a8a84b25 as DeParticipant
    link 0b4d8d88307a798d2817ae47ca16166071ad00bf87c8158588af719a3a8a84b25: 0:b4d8d88307a798d2817ae47ca16166071ad00bf87c8158588af719a3a8a84b25 @
    link 0b4d8d88307a798d2817ae47ca16166071ad00bf87c8158588af719a3a8a84b25: delta: -0.001000500 @
    link 0b4d8d88307a798d2817ae47ca16166071ad00bf87c8158588af719a3a8a84b25: #64;ever.live @ https://net.ever.live/accounts/accountDetails?id=0:b4d8d88307a798d2817ae47ca16166071ad00bf87c8158588af719a3a8a84b25
    link 0b4d8d88307a798d2817ae47ca16166071ad00bf87c8158588af719a3a8a84b25: #64;tonscan.io @ https://dev.tonscan.io/accounts/0:b4d8d88307a798d2817ae47ca16166071ad00bf87c8158588af719a3a8a84b25
    participant 0fa94171cb0565789224814561cc558e59315971ee9d03085de3dcb5f8b94d95e as @A
    link 0fa94171cb0565789224814561cc558e59315971ee9d03085de3dcb5f8b94d95e: 0:fa94171cb0565789224814561cc558e59315971ee9d03085de3dcb5f8b94d95e @
    link 0fa94171cb0565789224814561cc558e59315971ee9d03085de3dcb5f8b94d95e: delta: -2.551733186 @
    link 0fa94171cb0565789224814561cc558e59315971ee9d03085de3dcb5f8b94d95e: #64;ever.live @ https://net.ever.live/accounts/accountDetails?id=0:fa94171cb0565789224814561cc558e59315971ee9d03085de3dcb5f8b94d95e
    link 0fa94171cb0565789224814561cc558e59315971ee9d03085de3dcb5f8b94d95e: #64;tonscan.io @ https://dev.tonscan.io/accounts/0:fa94171cb0565789224814561cc558e59315971ee9d03085de3dcb5f8b94d95e
    participant 0cd7a4b9cd73044f33d256367627c393ac5fb170b07d2e45f119e1789b3c0acd9 as Token Root
    link 0cd7a4b9cd73044f33d256367627c393ac5fb170b07d2e45f119e1789b3c0acd9: 0:cd7a4b9cd73044f33d256367627c393ac5fb170b07d2e45f119e1789b3c0acd9 @
    link 0cd7a4b9cd73044f33d256367627c393ac5fb170b07d2e45f119e1789b3c0acd9: delta: -0.000003466 @
    link 0cd7a4b9cd73044f33d256367627c393ac5fb170b07d2e45f119e1789b3c0acd9: #64;ever.live @ https://net.ever.live/accounts/accountDetails?id=0:cd7a4b9cd73044f33d256367627c393ac5fb170b07d2e45f119e1789b3c0acd9
    link 0cd7a4b9cd73044f33d256367627c393ac5fb170b07d2e45f119e1789b3c0acd9: #64;tonscan.io @ https://dev.tonscan.io/accounts/0:cd7a4b9cd73044f33d256367627c393ac5fb170b07d2e45f119e1789b3c0acd9
    participant 073ed104a7397feaf4f4a5f847ebda71691c52fd79b0eb0a177cd4c77de5733f9 as Auction
    link 073ed104a7397feaf4f4a5f847ebda71691c52fd79b0eb0a177cd4c77de5733f9: 0:73ed104a7397feaf4f4a5f847ebda71691c52fd79b0eb0a177cd4c77de5733f9 @
    link 073ed104a7397feaf4f4a5f847ebda71691c52fd79b0eb0a177cd4c77de5733f9: delta: -0.000000308 @
    link 073ed104a7397feaf4f4a5f847ebda71691c52fd79b0eb0a177cd4c77de5733f9: #64;ever.live @ https://net.ever.live/accounts/accountDetails?id=0:73ed104a7397feaf4f4a5f847ebda71691c52fd79b0eb0a177cd4c77de5733f9
    link 073ed104a7397feaf4f4a5f847ebda71691c52fd79b0eb0a177cd4c77de5733f9: #64;tonscan.io @ https://dev.tonscan.io/accounts/0:73ed104a7397feaf4f4a5f847ebda71691c52fd79b0eb0a177cd4c77de5733f9
```

**DeAuction stake (same for remove stake):**
```mermaid
sequenceDiagram
    autonumber

    external -) 0fa94171cb0565789224814561cc558e59315971ee9d03085de3dcb5f8b94d95e: sendTransaction
    0fa94171cb0565789224814561cc558e59315971ee9d03085de3dcb5f8b94d95e ->> 0b4d8d88307a798d2817ae47ca16166071ad00bf87c8158588af719a3a8a84b25: stake
    0b4d8d88307a798d2817ae47ca16166071ad00bf87c8158588af719a3a8a84b25 ->> 0fa94171cb0565789224814561cc558e59315971ee9d03085de3dcb5f8b94d95e: #60;transfer#62;
    0b4d8d88307a798d2817ae47ca16166071ad00bf87c8158588af719a3a8a84b25 ->> 0960176c5825512b0402c710e535343837314eb3b8dd768a20de429e74cc8a1c6: stake
    0960176c5825512b0402c710e535343837314eb3b8dd768a20de429e74cc8a1c6 --) external: Stake
    0960176c5825512b0402c710e535343837314eb3b8dd768a20de429e74cc8a1c6 ->> 0b4d8d88307a798d2817ae47ca16166071ad00bf87c8158588af719a3a8a84b25: onStake
    0b4d8d88307a798d2817ae47ca16166071ad00bf87c8158588af719a3a8a84b25 --) external: Stake
    0b4d8d88307a798d2817ae47ca16166071ad00bf87c8158588af719a3a8a84b25 ->> 0fa94171cb0565789224814561cc558e59315971ee9d03085de3dcb5f8b94d95e: onStake

    participant external as #60;external#62;
    participant 0b4d8d88307a798d2817ae47ca16166071ad00bf87c8158588af719a3a8a84b25 as DeParticipant
    link 0b4d8d88307a798d2817ae47ca16166071ad00bf87c8158588af719a3a8a84b25: 0:b4d8d88307a798d2817ae47ca16166071ad00bf87c8158588af719a3a8a84b25 @
    link 0b4d8d88307a798d2817ae47ca16166071ad00bf87c8158588af719a3a8a84b25: delta: -0.001784141 @
    link 0b4d8d88307a798d2817ae47ca16166071ad00bf87c8158588af719a3a8a84b25: #64;ever.live @ https://net.ever.live/accounts/accountDetails?id=0:b4d8d88307a798d2817ae47ca16166071ad00bf87c8158588af719a3a8a84b25
    link 0b4d8d88307a798d2817ae47ca16166071ad00bf87c8158588af719a3a8a84b25: #64;tonscan.io @ https://dev.tonscan.io/accounts/0:b4d8d88307a798d2817ae47ca16166071ad00bf87c8158588af719a3a8a84b25
    participant 0960176c5825512b0402c710e535343837314eb3b8dd768a20de429e74cc8a1c6 as DeAuction
    link 0960176c5825512b0402c710e535343837314eb3b8dd768a20de429e74cc8a1c6: 0:960176c5825512b0402c710e535343837314eb3b8dd768a20de429e74cc8a1c6 @
    link 0960176c5825512b0402c710e535343837314eb3b8dd768a20de429e74cc8a1c6: delta: -0.000000069 @
    link 0960176c5825512b0402c710e535343837314eb3b8dd768a20de429e74cc8a1c6: #64;ever.live @ https://net.ever.live/accounts/accountDetails?id=0:960176c5825512b0402c710e535343837314eb3b8dd768a20de429e74cc8a1c6
    link 0960176c5825512b0402c710e535343837314eb3b8dd768a20de429e74cc8a1c6: #64;tonscan.io @ https://dev.tonscan.io/accounts/0:960176c5825512b0402c710e535343837314eb3b8dd768a20de429e74cc8a1c6
    participant 0fa94171cb0565789224814561cc558e59315971ee9d03085de3dcb5f8b94d95e as @A
    link 0fa94171cb0565789224814561cc558e59315971ee9d03085de3dcb5f8b94d95e: 0:fa94171cb0565789224814561cc558e59315971ee9d03085de3dcb5f8b94d95e @
    link 0fa94171cb0565789224814561cc558e59315971ee9d03085de3dcb5f8b94d95e: delta: -0.085293120 @
    link 0fa94171cb0565789224814561cc558e59315971ee9d03085de3dcb5f8b94d95e: #64;ever.live @ https://net.ever.live/accounts/accountDetails?id=0:fa94171cb0565789224814561cc558e59315971ee9d03085de3dcb5f8b94d95e
    link 0fa94171cb0565789224814561cc558e59315971ee9d03085de3dcb5f8b94d95e: #64;tonscan.io @ https://dev.tonscan.io/accounts/0:fa94171cb0565789224814561cc558e59315971ee9d03085de3dcb5f8b94d95e
```

**Finish sub voting (DeAuction consensus):**
```mermaid
sequenceDiagram
    autonumber

    external -) 0fa94171cb0565789224814561cc558e59315971ee9d03085de3dcb5f8b94d95e: sendTransaction
    0fa94171cb0565789224814561cc558e59315971ee9d03085de3dcb5f8b94d95e ->> 0729c0b4f98e6f4191d204069ce5fd0a56b4ca162d3bd29e8bf6489250f1eebab: finishSubVoting
    0729c0b4f98e6f4191d204069ce5fd0a56b4ca162d3bd29e8bf6489250f1eebab --) external: FinishSubVoting
    0729c0b4f98e6f4191d204069ce5fd0a56b4ca162d3bd29e8bf6489250f1eebab ->> 0fa94171cb0565789224814561cc558e59315971ee9d03085de3dcb5f8b94d95e: #60;transfer#62;

    participant external as #60;external#62;
    participant 0729c0b4f98e6f4191d204069ce5fd0a56b4ca162d3bd29e8bf6489250f1eebab as DeAuction
    link 0729c0b4f98e6f4191d204069ce5fd0a56b4ca162d3bd29e8bf6489250f1eebab: 0:729c0b4f98e6f4191d204069ce5fd0a56b4ca162d3bd29e8bf6489250f1eebab @
    link 0729c0b4f98e6f4191d204069ce5fd0a56b4ca162d3bd29e8bf6489250f1eebab: delta: -0.000000413 @
    link 0729c0b4f98e6f4191d204069ce5fd0a56b4ca162d3bd29e8bf6489250f1eebab: #64;ever.live @ https://net.ever.live/accounts/accountDetails?id=0:729c0b4f98e6f4191d204069ce5fd0a56b4ca162d3bd29e8bf6489250f1eebab
    link 0729c0b4f98e6f4191d204069ce5fd0a56b4ca162d3bd29e8bf6489250f1eebab: #64;tonscan.io @ https://dev.tonscan.io/accounts/0:729c0b4f98e6f4191d204069ce5fd0a56b4ca162d3bd29e8bf6489250f1eebab
    participant 0fa94171cb0565789224814561cc558e59315971ee9d03085de3dcb5f8b94d95e as @A
    link 0fa94171cb0565789224814561cc558e59315971ee9d03085de3dcb5f8b94d95e: 0:fa94171cb0565789224814561cc558e59315971ee9d03085de3dcb5f8b94d95e @
    link 0fa94171cb0565789224814561cc558e59315971ee9d03085de3dcb5f8b94d95e: delta: -0.030580073 @
    link 0fa94171cb0565789224814561cc558e59315971ee9d03085de3dcb5f8b94d95e: #64;ever.live @ https://net.ever.live/accounts/accountDetails?id=0:fa94171cb0565789224814561cc558e59315971ee9d03085de3dcb5f8b94d95e
    link 0fa94171cb0565789224814561cc558e59315971ee9d03085de3dcb5f8b94d95e: #64;tonscan.io @ https://dev.tonscan.io/accounts/0:fa94171cb0565789224814561cc558e59315971ee9d03085de3dcb5f8b94d95e
```

**DeAuction makes bid (same for confirm):**
```mermaid
sequenceDiagram
    autonumber

    external -) 0fa94171cb0565789224814561cc558e59315971ee9d03085de3dcb5f8b94d95e: sendTransaction
    0fa94171cb0565789224814561cc558e59315971ee9d03085de3dcb5f8b94d95e ->> 0729c0b4f98e6f4191d204069ce5fd0a56b4ca162d3bd29e8bf6489250f1eebab: makeBid
    0729c0b4f98e6f4191d204069ce5fd0a56b4ca162d3bd29e8bf6489250f1eebab ->> 0fa94171cb0565789224814561cc558e59315971ee9d03085de3dcb5f8b94d95e: #60;transfer#62;
    0729c0b4f98e6f4191d204069ce5fd0a56b4ca162d3bd29e8bf6489250f1eebab ->> 073ed104a7397feaf4f4a5f847ebda71691c52fd79b0eb0a177cd4c77de5733f9: makeDeBid
    073ed104a7397feaf4f4a5f847ebda71691c52fd79b0eb0a177cd4c77de5733f9 --) external: MakeBid
    073ed104a7397feaf4f4a5f847ebda71691c52fd79b0eb0a177cd4c77de5733f9 ->> 0680ab631986c211f6a4cc6646d7a2347677e599f76d7a8cd76a22ec458c4d64f: constructor
    073ed104a7397feaf4f4a5f847ebda71691c52fd79b0eb0a177cd4c77de5733f9 ->> 0729c0b4f98e6f4191d204069ce5fd0a56b4ca162d3bd29e8bf6489250f1eebab: onMakeBid
    0729c0b4f98e6f4191d204069ce5fd0a56b4ca162d3bd29e8bf6489250f1eebab --) external: MakeBid
    0729c0b4f98e6f4191d204069ce5fd0a56b4ca162d3bd29e8bf6489250f1eebab ->> 0fa94171cb0565789224814561cc558e59315971ee9d03085de3dcb5f8b94d95e: onMakeBid

    participant external as #60;external#62;
    participant 0729c0b4f98e6f4191d204069ce5fd0a56b4ca162d3bd29e8bf6489250f1eebab as DeAuction
    link 0729c0b4f98e6f4191d204069ce5fd0a56b4ca162d3bd29e8bf6489250f1eebab: 0:729c0b4f98e6f4191d204069ce5fd0a56b4ca162d3bd29e8bf6489250f1eebab @
    link 0729c0b4f98e6f4191d204069ce5fd0a56b4ca162d3bd29e8bf6489250f1eebab: delta: -0.001000550 @
    link 0729c0b4f98e6f4191d204069ce5fd0a56b4ca162d3bd29e8bf6489250f1eebab: #64;ever.live @ https://net.ever.live/accounts/accountDetails?id=0:729c0b4f98e6f4191d204069ce5fd0a56b4ca162d3bd29e8bf6489250f1eebab
    link 0729c0b4f98e6f4191d204069ce5fd0a56b4ca162d3bd29e8bf6489250f1eebab: #64;tonscan.io @ https://dev.tonscan.io/accounts/0:729c0b4f98e6f4191d204069ce5fd0a56b4ca162d3bd29e8bf6489250f1eebab
    participant 0680ab631986c211f6a4cc6646d7a2347677e599f76d7a8cd76a22ec458c4d64f as Bid
    link 0680ab631986c211f6a4cc6646d7a2347677e599f76d7a8cd76a22ec458c4d64f: 0:680ab631986c211f6a4cc6646d7a2347677e599f76d7a8cd76a22ec458c4d64f @
    link 0680ab631986c211f6a4cc6646d7a2347677e599f76d7a8cd76a22ec458c4d64f: delta: 0.488628000 @
    link 0680ab631986c211f6a4cc6646d7a2347677e599f76d7a8cd76a22ec458c4d64f: #64;ever.live @ https://net.ever.live/accounts/accountDetails?id=0:680ab631986c211f6a4cc6646d7a2347677e599f76d7a8cd76a22ec458c4d64f
    link 0680ab631986c211f6a4cc6646d7a2347677e599f76d7a8cd76a22ec458c4d64f: #64;tonscan.io @ https://dev.tonscan.io/accounts/0:680ab631986c211f6a4cc6646d7a2347677e599f76d7a8cd76a22ec458c4d64f
    participant 073ed104a7397feaf4f4a5f847ebda71691c52fd79b0eb0a177cd4c77de5733f9 as Auction
    link 073ed104a7397feaf4f4a5f847ebda71691c52fd79b0eb0a177cd4c77de5733f9: 0:73ed104a7397feaf4f4a5f847ebda71691c52fd79b0eb0a177cd4c77de5733f9 @
    link 073ed104a7397feaf4f4a5f847ebda71691c52fd79b0eb0a177cd4c77de5733f9: delta: 1.450520851 @
    link 073ed104a7397feaf4f4a5f847ebda71691c52fd79b0eb0a177cd4c77de5733f9: #64;ever.live @ https://net.ever.live/accounts/accountDetails?id=0:73ed104a7397feaf4f4a5f847ebda71691c52fd79b0eb0a177cd4c77de5733f9
    link 073ed104a7397feaf4f4a5f847ebda71691c52fd79b0eb0a177cd4c77de5733f9: #64;tonscan.io @ https://dev.tonscan.io/accounts/0:73ed104a7397feaf4f4a5f847ebda71691c52fd79b0eb0a177cd4c77de5733f9
    participant 0fa94171cb0565789224814561cc558e59315971ee9d03085de3dcb5f8b94d95e as @A
    link 0fa94171cb0565789224814561cc558e59315971ee9d03085de3dcb5f8b94d95e: 0:fa94171cb0565789224814561cc558e59315971ee9d03085de3dcb5f8b94d95e @
    link 0fa94171cb0565789224814561cc558e59315971ee9d03085de3dcb5f8b94d95e: delta: -2.042876076 @
    link 0fa94171cb0565789224814561cc558e59315971ee9d03085de3dcb5f8b94d95e: #64;ever.live @ https://net.ever.live/accounts/accountDetails?id=0:fa94171cb0565789224814561cc558e59315971ee9d03085de3dcb5f8b94d95e
    link 0fa94171cb0565789224814561cc558e59315971ee9d03085de3dcb5f8b94d95e: #64;tonscan.io @ https://dev.tonscan.io/accounts/0:fa94171cb0565789224814561cc558e59315971ee9d03085de3dcb5f8b94d95e
```

**DeAuction wins:**
```mermaid
sequenceDiagram
    autonumber

    external -) 0fa94171cb0565789224814561cc558e59315971ee9d03085de3dcb5f8b94d95e: sendTransaction
    0fa94171cb0565789224814561cc558e59315971ee9d03085de3dcb5f8b94d95e ->> 073ed104a7397feaf4f4a5f847ebda71691c52fd79b0eb0a177cd4c77de5733f9: finish
    073ed104a7397feaf4f4a5f847ebda71691c52fd79b0eb0a177cd4c77de5733f9 --) external: Finish
    073ed104a7397feaf4f4a5f847ebda71691c52fd79b0eb0a177cd4c77de5733f9 ->> 0729c0b4f98e6f4191d204069ce5fd0a56b4ca162d3bd29e8bf6489250f1eebab: onWin
    0729c0b4f98e6f4191d204069ce5fd0a56b4ca162d3bd29e8bf6489250f1eebab --) external: Win
    0729c0b4f98e6f4191d204069ce5fd0a56b4ca162d3bd29e8bf6489250f1eebab ->> 0fa94171cb0565789224814561cc558e59315971ee9d03085de3dcb5f8b94d95e: onWin
    073ed104a7397feaf4f4a5f847ebda71691c52fd79b0eb0a177cd4c77de5733f9 ->> 0d37297b1eba504c3ec3c9d3c4fab7c3d4eb5152e39e380d727705c20fa8a2ff3: onFinish
    0d37297b1eba504c3ec3c9d3c4fab7c3d4eb5152e39e380d727705c20fa8a2ff3 --) external: Finish
    0d37297b1eba504c3ec3c9d3c4fab7c3d4eb5152e39e380d727705c20fa8a2ff3 ->> 05ccd9b02b25ede74bdb3582a5a9d7b623c81e005d2fdf092bd3d5810da871128: onAuctionFinish

    participant external as #60;external#62;
    participant 0d37297b1eba504c3ec3c9d3c4fab7c3d4eb5152e39e380d727705c20fa8a2ff3 as AuctionRoot
    link 0d37297b1eba504c3ec3c9d3c4fab7c3d4eb5152e39e380d727705c20fa8a2ff3: 0:d37297b1eba504c3ec3c9d3c4fab7c3d4eb5152e39e380d727705c20fa8a2ff3 @
    link 0d37297b1eba504c3ec3c9d3c4fab7c3d4eb5152e39e380d727705c20fa8a2ff3: delta: -0.001791255 @
    link 0d37297b1eba504c3ec3c9d3c4fab7c3d4eb5152e39e380d727705c20fa8a2ff3: #64;ever.live @ https://net.ever.live/accounts/accountDetails?id=0:d37297b1eba504c3ec3c9d3c4fab7c3d4eb5152e39e380d727705c20fa8a2ff3
    link 0d37297b1eba504c3ec3c9d3c4fab7c3d4eb5152e39e380d727705c20fa8a2ff3: #64;tonscan.io @ https://dev.tonscan.io/accounts/0:d37297b1eba504c3ec3c9d3c4fab7c3d4eb5152e39e380d727705c20fa8a2ff3
    participant 0729c0b4f98e6f4191d204069ce5fd0a56b4ca162d3bd29e8bf6489250f1eebab as DeAuction
    link 0729c0b4f98e6f4191d204069ce5fd0a56b4ca162d3bd29e8bf6489250f1eebab: 0:729c0b4f98e6f4191d204069ce5fd0a56b4ca162d3bd29e8bf6489250f1eebab @
    link 0729c0b4f98e6f4191d204069ce5fd0a56b4ca162d3bd29e8bf6489250f1eebab: delta: -0.001000413 @
    link 0729c0b4f98e6f4191d204069ce5fd0a56b4ca162d3bd29e8bf6489250f1eebab: #64;ever.live @ https://net.ever.live/accounts/accountDetails?id=0:729c0b4f98e6f4191d204069ce5fd0a56b4ca162d3bd29e8bf6489250f1eebab
    link 0729c0b4f98e6f4191d204069ce5fd0a56b4ca162d3bd29e8bf6489250f1eebab: #64;tonscan.io @ https://dev.tonscan.io/accounts/0:729c0b4f98e6f4191d204069ce5fd0a56b4ca162d3bd29e8bf6489250f1eebab
    participant 05ccd9b02b25ede74bdb3582a5a9d7b623c81e005d2fdf092bd3d5810da871128 as NeverElector
    link 05ccd9b02b25ede74bdb3582a5a9d7b623c81e005d2fdf092bd3d5810da871128: 0:5ccd9b02b25ede74bdb3582a5a9d7b623c81e005d2fdf092bd3d5810da871128 @
    link 05ccd9b02b25ede74bdb3582a5a9d7b623c81e005d2fdf092bd3d5810da871128: delta: 1.832877615 @
    link 05ccd9b02b25ede74bdb3582a5a9d7b623c81e005d2fdf092bd3d5810da871128: #64;ever.live @ https://net.ever.live/accounts/accountDetails?id=0:5ccd9b02b25ede74bdb3582a5a9d7b623c81e005d2fdf092bd3d5810da871128
    link 05ccd9b02b25ede74bdb3582a5a9d7b623c81e005d2fdf092bd3d5810da871128: #64;tonscan.io @ https://dev.tonscan.io/accounts/0:5ccd9b02b25ede74bdb3582a5a9d7b623c81e005d2fdf092bd3d5810da871128
    participant 073ed104a7397feaf4f4a5f847ebda71691c52fd79b0eb0a177cd4c77de5733f9 as Auction
    link 073ed104a7397feaf4f4a5f847ebda71691c52fd79b0eb0a177cd4c77de5733f9: 0:73ed104a7397feaf4f4a5f847ebda71691c52fd79b0eb0a177cd4c77de5733f9 @
    link 073ed104a7397feaf4f4a5f847ebda71691c52fd79b0eb0a177cd4c77de5733f9: delta: -1.871358223 @
    link 073ed104a7397feaf4f4a5f847ebda71691c52fd79b0eb0a177cd4c77de5733f9: #64;ever.live @ https://net.ever.live/accounts/accountDetails?id=0:73ed104a7397feaf4f4a5f847ebda71691c52fd79b0eb0a177cd4c77de5733f9
    link 073ed104a7397feaf4f4a5f847ebda71691c52fd79b0eb0a177cd4c77de5733f9: #64;tonscan.io @ https://dev.tonscan.io/accounts/0:73ed104a7397feaf4f4a5f847ebda71691c52fd79b0eb0a177cd4c77de5733f9
    participant 0fa94171cb0565789224814561cc558e59315971ee9d03085de3dcb5f8b94d95e as @A
    link 0fa94171cb0565789224814561cc558e59315971ee9d03085de3dcb5f8b94d95e: 0:fa94171cb0565789224814561cc558e59315971ee9d03085de3dcb5f8b94d95e @
    link 0fa94171cb0565789224814561cc558e59315971ee9d03085de3dcb5f8b94d95e: delta: -0.031160056 @
    link 0fa94171cb0565789224814561cc558e59315971ee9d03085de3dcb5f8b94d95e: #64;ever.live @ https://net.ever.live/accounts/accountDetails?id=0:fa94171cb0565789224814561cc558e59315971ee9d03085de3dcb5f8b94d95e
    link 0fa94171cb0565789224814561cc558e59315971ee9d03085de3dcb5f8b94d95e: #64;tonscan.io @ https://dev.tonscan.io/accounts/0:fa94171cb0565789224814561cc558e59315971ee9d03085de3dcb5f8b94d95e
```

<details>
<summary>Click here to see main function for DeAuction</summary>

```solidity
function finishSubVoting() external;
function allowedPrice() external view returns (PriceRange allowed);
function calcBidHash(uint128 price, uint256 salt) external view returns (uint256 hash);
function makeBid(uint256 hash) external view;
function confirmBid(uint128 price, uint256 salt) external;
function onWin(uint128 price, uint128 amount) external override;
function pingAuctionFinish() external view;
function checkAggregator() external view returns (bool isFair);
function slash() external;
```

</details>

## Viewer
Viewer listen for events and display all info about current auction

![viewer](docs/viewer.png)

## Constants

All contact system is very configurable. There are several configuration places:
1) contracts/utils/Constants.sol (MIN_LOT_SIZE) - contact constants
2) contracts/utils/Gas.sol - contact gas (already optimized)
3) scripts/3-deploy-auction-root.js - deploy default params for Auctions and DeActions,
optimal value is specified in comments 
4) scripts/5-deploy-auction-root.js - deploy params for DevNet tests

## Other features
DeAuction supports both TIP3.1 standard (broxus realization) and Extra Currency Collection (ECC).
There is common [DeAuction](contracts/DeAuction.sol) abstract contract, and specified
realization [DeAuctionTIP3](contracts/DeAuctionTIP3.sol) and [DeAuctionECC](contracts/DeAuctionECC.sol)

All contracts have separate list of interfaces, you can find they
in `contracts/interfaces/internal` folder

## Demo
**Important! All demos must be started only from project root folder (not from demo folder)!**

There are several demos for quick verifying of work:
1) `./demo/1-init.sh` - initializing project
(do it after steps that describes in [setup environment](#Setup-environment)!)
2) `./demo/2-build.sh.sh` - compile source files
3) `./demo/3-test.sh` - test all
4) `./demo/4-deploy.sh` - deploy to network passed in `locklift.config.js`
5) `./demo/5-integration.sh` - call only after 4th step, demo of integration with
[solution in Phase 1](https://firebasestorage.googleapis.com/v0/b/ton-labs.appspot.com/o/documents%2Fapplication%2Fpdf%2Fjz5i5hcndnktkekjat-NOT%20Pruvendo%20Implementation%20draft%203.pdf?alt=media&token=015ee545-fe73-432c-a525-9a4e672128ba)

Additional script demo for manual testing: `./demo/demo-devnet.sh`
(it deploys in network that specified in `locklift.config.js`)

Or just use `build/TestAuctionRoot.abi.json` with Auction Root in DevNet
at address `0:d37297b1eba504c3ec3c9d3c4fab7c3d4eb5152e39e380d727705c20fa8a2ff3`
