# Chainlink Standalone Tests Successful

This repo contains files used to successfully test Chainlink's AnyAPI and VRF2 products as standalones on the Koven and Rinkbey testnets.


* `ChainlinkAnyAPI.sol`: Successfully deployed Koven at 0xe106A4E201e638610b0CcED7981158b1bba8A228
* `ChainlinkVRF.sol`: Successfully deployed Rinkeby at 0xEbA883FFC1d77A7Ee3B53bF779B8C5cF69711376

As shown in the showcase video, these to implementations were successfully implemented.


# Next Steps

The next milestone is to incorporate Chainlink's AnyAPI, Data feeds, VRF1, and VRF2 into existing blockchain applications and products.

For full transparency, unsuccessful attempts were made to integrate Chainlink VRF2 within my random number generator toy-model running on the Rinkeby Testnet. The file used for the attempted integrations is `RaffleVRF3.sol`

The errors can basically be summarized as "unable to calculate gas". For example:

```
$ npx hardhat run scripts/interact-vrf.js --network rinkeby
Error: cannot estimate gas; transaction may fail or may require manual gas limit [ See: https://links.ethers.org/v5-errors-UNPREDICTABLE_GAS_LIMIT ] (error={"name":"ProviderError","code":3,"_isProviderError":true,"data":"0x4e487b710000000000000000000000000000000000000000000000000000000000000032"}, method="estimateGas", 
```

Fortunately, as you can see in the code for `RaffleVRF3.sol`, the toy-model uses a pseudo-random number generator as a fallback.  And, it works flawlessly!  

