// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12; //0. security (optional): remove the ^ to lock pragma to a specific compiler version!

import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

contract RaffleVRF3 is VRFConsumerBaseV2 {  //0xeba883ffc1d77a7ee3b53bf779b8c5cf69711376

    /*
     * 1. Owner only priveleges
     * 2. Create a seed: Random and undertmistic number generated by contract deployer. Used to Generate pseudo random number
     * 3a. Usage Throtting: Restrict by wallet and IP addresses by recording last time these addresses interacted with contract. 
     * 3b.                  Restrict by IP by only letting 1 IP address hit per throttle
     * 4. 
     * 5. 
     *
     * PRO-TIP 1: Initialize state variables (globals) in constructor (or later when needed) to save gas
     * PRO-TIP 2: setting variables to private makes them very difficult but not impossible to read
     *            Also, arguments sent to public functions are readable and not encrypted
     * PRO-TIP 3: Arrays are more complex than maps, expensive to add. 2D arrays must be same datatype
     *            https://ethereum.stackexchange.com/a/42440/3506
     */


    //Globals for Game
 
    address payable private owner;                                   //1. security  https://solidity-by-example.org/payable/ 
    address private staff;
    uint256 private seed;                                           //2. security
    uint256 public throttleUser;                                    //3a. security
    mapping(bytes32 => uint256) public lastPlayedTimestamp;         //3a. security apply throttle by IP address. Store in simple hash table
    uint256 public lastWinningNumber;
    


    //Publically viewable and updatable by contract owner
    uint256 public jackpotPrizeAmount;            // Users are eligible to win entire balance of contract      
    uint8   public modulo;                        // Odds of winning = 1/modulo  any number between 0 and 255
    uint256 public minWager;                      // userDepsosit: User must wager to play. part of the 'commit-and-reveal' design pattern
    uint256 public devFee;                        // Devs have mouths to feed and bills to pay too!

    //track user activity


    struct UserActivityLog{ //https://coursetro.com/posts/code/102/Solidity-Mappings-&-Structs-Tutorial
        uint256 totalDeposits;
        uint256 totalWins; 
        uint256 totalLosses;
        int256  balance;
        bytes32 IPAddress;                  //3b. security
        uint256 lastPlayedTimestamp;        //3a. security
    }

    /*
    * A. Declare variable "users" of custom datatype 'UserActivityLog' object.
    *   a. This is a Mapping of address to UserActivityLog datatype
    *   b. users[address] is struct UserActivityLog and will return contents for s single user
    *   c. One log for each user that is mapped (i.e., can be filtered and key-valued) by address
    */
    mapping(address => UserActivityLog) users; 
    /*
    *  Example 1: Multiple logs for each user. 1 address maps to an array of UserActivityLog structs
    *       mapping(address => UserActivityLog[]) users;
    */
    
    /*
    *  Example 2: An array of structs. No filtering by address
    *       UserActivityLog[] users;
    */ 
    

    /**
     * B. userLogs is an array of addresses.  Define address array to store user addresses
     *   a. Solidity is unable to directly return the users mapping and iterate through these available users.
     *   b. Manually build list of user activity logs with userLogs and then make a specific function
     *       call to grab the UserActivityLog's information based on the Ethereum address. 
     *   c. A mapping can only be returned in a struct in a function. a mapping (or a struct containing a mapping) cannot be created in memory
     *   d. IPAddress mapped to wallet only possible if arrays are updated in same transaction
     */
    address[] public userLogs; // utilty func: allows binding (length, lookup, etc) to struct UserActivityLog
    bytes32[] private IPAddressLog; //security audit: should be private and exposed by onlyStaff func
    address[] private bindWalletToIPByIndex; //security audit: facilitate attacker tracing 
    
    /**
    * Publish winning number and round
    * https://www.tutorialspoint.com/solidity/solidity_events.htm
    *
    * 1. event and emit publicizes tx data for perma storgage on blockchain
    * 2. allows web apps to read the data easily
    */
    event WinningNumber(uint256 indexed raffleCounter, uint256 winningNumber); 

    /**
    * START CHAINLINK VRF CODE
    */  
    VRFCoordinatorV2Interface COORDINATOR;
    LinkTokenInterface LINKTOKEN;

    uint64 s_subscriptionId; // Your subscription ID.
    address vrfCoordinator = 0x6168499c0cFfCaCD319c818142124B7A15E857ab;
    address link = 0x01BE23585060835E02B77ef475b0Cc51aA1e0709;
    bytes32 keyHash = 0xd89b2bf150e3b9e13446986e571fb9cab24b13cea0a43ea20a6049a85cc807cc;
    uint32 callbackGasLimit = 100000;
    uint16 requestConfirmations = 3;
    uint32 numWords = 2;

    uint256[] public s_randomWords;
    uint256 public s_requestId;
    address s_owner;
    /**
    * END CHAINLINK VRF CODE
    */ 

    constructor( address _staff, uint64 subscriptionId ) payable VRFConsumerBaseV2(vrfCoordinator){ //payable needed to fund contact when deployed

        require(msg.value > 0, "Contract must be funded at deployment");            // Contract must be funded >= prize amoubnt to be deployable 

        modulo = 100;                                                                // 1/100 = 1% win probability 
        seed = uint256( keccak256( abi.encodePacked( block.timestamp, block.difficulty) ) );                                // Random number must be seeded at deployment
        jackpotPrizeAmount = msg.value;                                              // Prize amount must be specified at deployment
        owner = payable(msg.sender);                                                 // Define owner as deployer of contract
        throttleUser =  10 minutes;                                                  // User may only make 1 wager every n minutes
        minWager = 1 * 10**16;                                                       // Minimum wager is x of the native token
        devFee = 2 * 10**17;                                                         // Give the devs some love!
        staff  = _staff;

        /**
        * START CHAINLIK VARIABLE INITS
        */ 
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        LINKTOKEN = LinkTokenInterface(link);
        s_owner = msg.sender;
        s_subscriptionId = subscriptionId;
        /**
        * ENDCHAINLIK VARIABLE INITS
        */ 

    } 

    modifier onlyOwner() { //https://www.tutorialspoint.com/solidity/solidity_function_modifiers.htm
        require(msg.sender == owner, "This function may only be called by contract owner");
        _;
    }   

    modifier onlyStaff() { 
        require(msg.sender == owner || msg.sender == staff, "Function may only be called by the owner or a staff member ");
        _;
    }  

    modifier noEOA() {
        require(msg.sender == tx.origin, "Smart contracts cannot call this function");
        _;
    }

    /*
     * 5. Commit and reveal pattern
     *
     * PRO-TIP 3:  The value  of address(this).balance in payable methods is increased by msg.value before the body the ayable method executes
     */
    function userCommit( uint8 guess, bytes32 _IPAddress, uint8 chooseVRF1or2 ) public payable noEOA{ // guess is between 0 to 255
        //address(this).balance
        require( jackpotPrizeAmount > 0, "This raffle game is offline. Try again tomorrow" );
        require( msg.value >= minWager, 'Please desposit the minimum amount to play');
        require( guess >= 0, "Please guess a nuber between 1 and 100");
        require( guess <= modulo, "Please guess a number between 1 and 100");

        //soft security check
        bool _didUserCommit = true;
        
        runRaffle( guess, _IPAddress, _didUserCommit, chooseVRF1or2 );

    }
   

    function runRaffle( uint8 guess, bytes32 _IPAddress, bool _didUserCommit, uint8 chooseVRF1or2 ) private noEOA{ //shall only be called when funds are desposited

        /** 
         * 6. Prevent smart contracts from calling this method by added a requirement that the caller of 
         *    the enter method does not have any smart contract code associated with its address on on chain
         *    This is method on Ethereum that guarantees that the caller is not a smart contract
         */
        // require(msg.sender == tx.origin, "Smart contracts cannot call this function");

        /** 
         * Applying Item 5. Enforce Commit and reveal pattern
         */
        require(_didUserCommit == true, "A wager must be placed");


        /** 
         * Applying Item 3a. Impose __wallet-based__ 'usage throttling' via a timeout to prevent continous contract calls (cooldown function)
         */
        require( users[msg.sender].lastPlayedTimestamp +  throttleUser < block.timestamp, "Wallet Filter: Please wait a few minutes to play again");
        
        /** 
         * Applying Item 3b. Impose __IP-based__ 'usage throttling' for people switching wallets on same IP Address
         *
         *  @dev notes:
         *      i.  bytes32 to save gas and facilitate privacy 
         */   
        require( testIPFilter(_IPAddress) < block.timestamp, "IP Filter: Please wait a few minutes to play again");
        
        updateIPAddressLogs( _IPAddress ); 
  
        uint256 pseudoRandomNumber;

        if (chooseVRF1or2 == 1 ){ // #1 is Chainlink

            requestRandomWords();

            pseudoRandomNumber =  s_randomWords[0];
            seed               =  s_randomWords[1]; //enhance pseudo with chainlink seed

        }else{

            pseudoRandomNumber = setPseudoRandomNumber();
        }

        uint256 _win; 
        uint256 _loss;
        uint256 _balanceChange;

        uint256 userPayout = jackpotPrizeAmount + msg.value;

        /** 
         * 7. Test user guess, reset all security checks, then update user log 
         */

        if (pseudoRandomNumber == guess) {

            //require( jackpotPrizeAmount <= address(this).balance, "Trying to withdraw more money than the contract has." );

            _win = 1;
            _loss = 0;
            _balanceChange = userPayout;

            payable(msg.sender).transfer(userPayout);

        } else{

            _loss = 1;
            _win = 0;
            _balanceChange = msg.value;
            
            //( (100 - 100 * devFee/10**18 ) * msg.value )/100; //this is a nightmare
        }


        //reset soft security checks
        _didUserCommit = false;        

        //create or update user activity log
        uint256 _doesUserExist = doesUserExist(msg.sender);

        if (  _doesUserExist == 0) {

            createUserActivityLog(  msg.value, _win, _loss, _balanceChange, _IPAddress, block.timestamp );

        } else {

            updateUserActivityLog( msg.value, _win, _loss, _balanceChange, _IPAddress, block.timestamp );

        }

        //don't reveal until program passes pay function
        emit WinningNumber( getAllWalletAddresses().length, pseudoRandomNumber );
        lastWinningNumber = pseudoRandomNumber;   

        //update jackpot amount
        jackpotPrizeAmount = address(this).balance * devFee/10**18; 

    } 


    /*
     * 6a. Generate Pseudo Random Number: 
     *      = block.difficulty +  block.timestamp +  seed + randAddress + randTimestamp
     */
    function setPseudoRandomNumber() private returns (uint256){

        //1. generate dynamic random number based on 3 dynamic inputs
        //NB: may possibly improve pseudo randomness by dynamically 
        //choosing a timestamp and address from the userLogs array

        uint256 index;
        uint256 arrayLen = getAllWalletAddresses().length;
        address randAddress = 0x4B0897b0513fdC7C541B6d9D7E929C4e5364D2dB;
        uint256 randTimestamp = 345678765;

       
        if ( lastWinningNumber >= arrayLen){

            index = lastWinningNumber - arrayLen;
            //if (index > arrayLen) index = 0;

        } else {

            index = arrayLen - lastWinningNumber;
            
        }
        
        if (index <= arrayLen && index != 0){
            randAddress = getOneWalletAddressByIndex( index );
            randTimestamp = users[randAddress].lastPlayedTimestamp;
        }
        
        uint256 pseudoRandomNumber = uint256( keccak256( abi.encodePacked( block.timestamp, block.difficulty, seed, randAddress, randTimestamp) ) );

        //2. store seed for next round
        seed = pseudoRandomNumber;
       
        //3. then generate a number between 1 and 100
        pseudoRandomNumber = (pseudoRandomNumber  % modulo) + 1;  

        return pseudoRandomNumber;

    }  

    function createUserActivityLog( uint256 msgValue, uint256 _win, uint256 _loss, uint256 _balanceChange, bytes32 _IPAddress,
                                    uint256 _lastPlayedTimestamp) private{

        int256 intBalance; 
        
        if ( _win == 0 ){

            intBalance = -int256(_balanceChange);

        } else {

            intBalance =  int256(_balanceChange);

        }
        /* 
        * Solidity datatypes need a storage location: storage, memory, or calldata (external views) @see https://stackoverflow.com/a/33839164/946957
        *  
        * Memory storage is cheaper and may be used for temp storing of arrays & structs when doing intermediate calculations
        * It's only available inside methods. Non-numeric datatypes must have storage type declared
        *
        * Examples 1 and 2 assume users is a mapping of address to a single struct.
        * 
        * Example 1: This is an example of using memory storage. But use of memory is reduntant
        *
        *  UserActivityLog memory singleUser = UserActivityLog( msgValue, _win, _loss, intBalance, _IPAddress, _lastPlayedTimestamp);
        *  users[msg.sender] = singleUser;
        *
        * Example 2: This is an example of direct storage. Gas cost is the same as above!
        */

        users[msg.sender] = UserActivityLog( msgValue, _win, _loss, intBalance, _IPAddress, _lastPlayedTimestamp);

        userLogs.push(msg.sender);

        // Example 3:  Assumes users is a mapping of address to an arr of stucts. 
        // @see https://ethereum.stackexchange.com/q/59420/3506
        // users[_address].push( UserActivityLog(_deposit, _win, _loss, _balance, didUserCommit, _IPAddress, _lastpPlayedTimestamp) );

        //bad example:
        //source: https://ethereum.stackexchange.com/q/42769/3506
        //users[_address] = UserActivityLog( {totalDeposits: _deposit ...lastPlayedTimestamp: _lastpPlayedTimestamp} ) 

    }  


    function updateUserActivityLog( uint256 _msgValue, uint256 _win, uint256 _loss, uint256 _balanceChange, bytes32 _IPAddress, 
                                    uint256 _lastPlayedTimestamp ) private{

        int256  intBalance;
        
        if ( _win == 0 ){

            intBalance = -int256(_balanceChange);

        } else {

            intBalance =  int256(_balanceChange);

        }
    
        users[msg.sender].totalDeposits       =   _msgValue      + users[msg.sender].totalDeposits;
        users[msg.sender].totalWins           =   _win           + users[msg.sender].totalWins;
        users[msg.sender].totalLosses         =   _loss          + users[msg.sender].totalLosses;
        users[msg.sender].balance             =   intBalance     + users[msg.sender].balance;
        users[msg.sender].IPAddress           =   _IPAddress;
        users[msg.sender].lastPlayedTimestamp =   _lastPlayedTimestamp;

    }  

    function getAllWalletAddresses() view public returns( address[] memory ){
        return userLogs; 
    }  

    function getOneWalletAddressByIndex( uint256 _index ) view public returns( address ){
        return userLogs[_index];
    }  

    function doesUserExist( address _address) view private returns( uint256 ){      
        return ( users[_address].lastPlayedTimestamp );
    }  

    /*
    * @dev note: sensitive limit to wallet owner and game owner
    */
    function getUserActivityLog( address _address) view public returns(uint256, uint256, uint256, int256, bytes32, uint256 ) {   
   
        if (_address == msg.sender || msg.sender == owner || msg.sender == staff) {
            return (
                    users[_address].totalDeposits, 
                    users[_address].totalWins, 
                    users[_address].totalLosses, 
                    users[_address].balance,
                    users[_address].IPAddress, 
                    users[_address].lastPlayedTimestamp 
            );
        }
        return (0, 0, 0, 0, 0, 0);
    }  

    /*
    * @dev note: To end payouts directly to charties, staff members, or others
    */
    function withdraw(uint256 amount, address payable destAddress) public onlyOwner{
        require(amount <= address(this).balance - jackpotPrizeAmount, "Can't withdraw more than current balance");
        destAddress.transfer(amount);
    } 

    receive() external payable {}

    function addFunds( uint256 amount ) payable public {
        require(msg.value == amount, "Amount sent != to amount indicated");
    } 

    function getBlockTime() public view returns(uint256) {
        return block.timestamp;
    }

    function setJackpotPrizeAmount( uint256 _jackpotPrizeAmount ) public onlyOwner{ 
        jackpotPrizeAmount = _jackpotPrizeAmount;
    }

    function getBalance() public view returns(uint256) { 
        return  address(this).balance;     
    } 

    function setDevFee( uint256 _devFee) public onlyOwner{
        devFee = _devFee;
    }

    function getDeveloperRefund() public view onlyStaff returns( uint256 ){  
        return  address(this).balance - jackpotPrizeAmount;     
    } 

    function withdrawDeveloperRefund() public onlyStaff{
        uint256 refund = address(this).balance - jackpotPrizeAmount;
        owner.transfer( refund );
    } 

    function getIPAddressLogs() public view onlyStaff returns( bytes32[] memory ){   
        return IPAddressLog;
    } 

    function getBindWalletToIpByIndex() public view  onlyStaff returns( address[] memory ){   
        return bindWalletToIPByIndex;
    } 

    //TODO: delete in production: for unit testing only
    function testEmitter( uint256 _raffleCounter, uint256 _winningNumber) public onlyOwner{ 
        emit WinningNumber(_raffleCounter, _winningNumber);
    }

    function setThrottleUser( uint256 _throttleUser) public onlyOwner{
        throttleUser = _throttleUser;
    }

    function setMinWager( uint256 _minWager) public onlyOwner{
        minWager = _minWager;
    }

    function setProbabiltyModulo( uint8 _probability) public onlyOwner{
        modulo = _probability;
    }

    function testIPFilter (bytes32 _ip ) private view returns( uint256 ){   
        return getLastTimeStampByIP(_ip) +  throttleUser;
    }

    function updateIPAddressLogs(bytes32 _IPAddress ) private{

        lastPlayedTimestamp[_IPAddress] = block.timestamp;

        IPAddressLog.push( _IPAddress ); 

        bindWalletToIPByIndex.push( msg.sender ); //@dev same index as IPAddress.log

    } 

    //TODO: can this be called in internally if set to onlyOwner? No, it cannot
    function getLastTimeStampByIP( bytes32 _IPAddress ) public view returns(uint256){    
        return lastPlayedTimestamp[_IPAddress];
    }

    function setOwner( address payable _owner ) public onlyOwner{
        owner = _owner;
    }

    function getOwner() public view onlyStaff returns( address ){ //or address payable
        return owner;
    }

    function setStaffWalletAddress( address _staffMemberAddress ) public onlyOwner{
        staff = _staffMemberAddress;
    }
  
    function getStaffWalletAddress() public view onlyStaff returns( address ){
        return staff;
    }

    function endGame() public onlyStaff{ 
        selfdestruct(owner); 
    }   
 
    /**
    * START CHAINLINK VRF CODE
    */
    // Assumes the subscription is funded sufficiently.
    function requestRandomWords() private { //default was external visiibility
        // Will revert if subscription is not set and funded.
        s_requestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
    }

    function fulfillRandomWords( uint256, /* requestId */ uint256[] memory randomWords) internal override {
        s_randomWords = randomWords;
    }

    //   modifier onlyOwner() {
    //     require(msg.sender == s_owner);
    //     _;
    //   }
    /**
    * END CHAINLINK VRF CODE
    */

}