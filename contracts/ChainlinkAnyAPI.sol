// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";

/**
 * Request testnet LINK and ETH here: https://faucets.chain.link/
 * Find information on LINK Token Contracts and get the latest ETH and LINK faucets here: https://docs.chain.link/docs/link-token-contracts/
 *
 * Deloyed To: 0xe106A4E201e638610b0CcED7981158b1bba8A228
 *
 * Original Name: APIConsumer
 *
 * Tutorial: https://docs.chain.link/docs/advanced-tutorial/  https://youtu.be/ay4rXZhAefs?t=453  (5:33 - 10:24)
 * Source:
 */

/**
 * THIS IS AN EXAMPLE CONTRACT WHICH USES HARDCODED VALUES FOR CLARITY.
 * PLEASE DO NOT USE THIS CODE IN PRODUCTION.
 */

 //

contract ChainlinkAnyAPI is ChainlinkClient {
    using Chainlink for Chainlink.Request;
  
    uint256 public volume;
    uint256 public ethereumPrice;
    
    uint256 public balance; //custom vars
    address public owner;  //custom vars
    
    address private oracle;
    bytes32 private jobId;
    uint256 private fee;
    
    /**
     * Network: Kovan
     * Oracle: 0xc57B33452b4F7BB189bB5AfaE9cc4aBa1f7a4FD8 (Chainlink Devrel   
     * https://market.link/jobs/f5357a30-54b7-4a68-b6a8-ae55d4eda987
     *
     * Job ID: d5270d1c311941d0b08bead21fea7747
     * Fee: 0.1 LINK
     */
    /**
     * Network: Harmony
     * Oracle:
     * Node)
     * Job ID: 
     * Fee: 
     */   
    /**
     * Network: Mumbai
     * Oracle: 0x0bDDCD124709aCBf9BB3F824EbC61C87019888bb   (Mumbai Testnet - Matrixed.link)
     * https://market.link/jobs/4002bb77-a1c0-4dcc-8480-9130fa7bb26f
     *
     * Job ID: 2bb15c3f9cfc4336b95012872ff05092
     * Fee: 0.01 LINK
     */   
    /**
     * Network: Rinkeby
     * Oracle: 0xF59646024204a733E1E4f66B303c9eF4f68324cC
     * https://market.link/jobs/5b3aa141-4fd8-4629-b16f-e86629f46490
     *
     * Job ID: 6a92925dbb0e48e9b375b1deac4751c0
     *
     * Fee: 0.1 LINK
     */  
    constructor() {
        setPublicChainlinkToken();
        oracle = 0xc57B33452b4F7BB189bB5AfaE9cc4aBa1f7a4FD8;
        jobId = "d5270d1c311941d0b08bead21fea7747";
        fee = 0.1 * 10 ** 18; // (Varies by network and job)
    }
    
    /**
     * Create a Chainlink request to retrieve API response, find the target
     * data, then multiply by 1000000000000000000 (to remove decimal places from data).
     */
    function requestVolumeData() public returns (bytes32 requestId) 
    {
        Chainlink.Request memory request = buildChainlinkRequest(jobId, address(this), this.fulfill.selector);
        
        // Set the URL to perform the GET request on
        request.add("get", "https://min-api.cryptocompare.com/data/pricemultifull?fsyms=ETH&tsyms=USD");
        
        // Set the path to find the desired data in the API response, where the response format is:
        // {"RAW":
        //   {"ETH":
        //    {"USD":
        //     {
        //      "VOLUME24HOUR": xxx.xxx,
        //     }
        //    }
        //   }
        //  }
        request.add("path", "RAW.ETH.USD.VOLUME24HOUR");
        
        // Multiply the result by 1000000000000000000 to remove decimals
        int timesAmount = 10**18;
        request.addInt("times", timesAmount);
        
        // Sends the request
        return sendChainlinkRequestTo(oracle, request, fee);
    }
    
    /**
     * Create a Chainlink request to retrieve API response, find the target price
     * data, then multiply by 100 (to remove decimal places from price).
     */
    function requestEthereumPrice() public returns (bytes32 requestId) 
    {
        Chainlink.Request memory request = buildChainlinkRequest(jobId, address(this), this.fulfill.selector);
        
        // Set the URL to perform the GET request on
        request.add("get", "https://min-api.cryptocompare.com/data/price?fsym=ETH&tsyms=USD");
        
        // Set the path to find the desired data in the API response, where the response format is:
        // {"USD":243.33}
        request.add("path", "USD");
        
        // Multiply the result by 100 to remove decimals
        request.addInt("times", 100);
        
        // Sends the request
        return sendChainlinkRequestTo(oracle, request, fee);
    }
    
    /**
     * Receive the response in the form of uint256
     */ 
    function fulfillPriceData(bytes32 _requestId, uint256 _price) public recordChainlinkFulfillment(_requestId)
    {
        ethereumPrice = _price;
    }

    /**
     * Receive the response in the form of uint256
     */ 
    function fulfill(bytes32 _requestId, uint256 _volume) public recordChainlinkFulfillment(_requestId)
    {
        volume = _volume;
    }

    function withdrawLink(uint256 amount, address payable destAddress) public {
        require(msg.sender == owner, " only onwner can all this function");
        require(amount <= balance, "Can't withdraw more than current balance");
        destAddress.transfer(amount);
        balance -= amount;
    }  

    //function withdrawLink() external {} //- Implement a withdraw function to avoid locking your LINK in the contract
}
