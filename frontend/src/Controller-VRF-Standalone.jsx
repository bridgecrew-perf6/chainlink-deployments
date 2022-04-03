import React, { useEffect, useState } from "react";
import { ethers } from "ethers";
import abi from './../../utils/ChainlinkVRF.json';

const Controller = () => {

    const { ethereum } = window
    const [currentAccount, setCurrentAccount] = useState("");
    const [arrayRandomNumbers, setArrayRandomNumbers] = useState([]);

    const contractAddress = "0xEbA883FFC1d77A7Ee3B53bF779B8C5cF69711376";
    const contractABI = abi.abi;

    const provider = new ethers.providers.Web3Provider(ethereum); //fix 1
    const signer = provider.getSigner();
    const contract = new ethers.Contract(contractAddress, contractABI, signer);




    const handleGetVRF = async ()=>{

        /*const uglyArray =*/ await contract.requestRandomWords();

        let arrayRandomNumbers = []
        let temp

    //    const arrayRandomNumbers = uglyArray.map( singleItem  =>({

    //         function(){parseInt(singleItem) % 100 }


    //     }))

        temp  = await contract.s_randomWords(0)
        arrayRandomNumbers[0] = ethers.utils.formatEther(temp) % 100
        temp  = await contract.s_randomWords(1)
        arrayRandomNumbers[1] = ethers.utils.formatEther(temp) % 100
        
        setArrayRandomNumbers(arrayRandomNumbers)

    }


    const checkIfWalletIsConnected = async () => {
        try {

            if (!ethereum) {
                console.log("Make sure you have metamask!");
                return;
            } else {
                console.log("We have the ethereum object", ethereum);
            }

            const accounts = await ethereum.request({ method: 'eth_accounts' });

            if (accounts.length !== 0) {
                const account = accounts[0];
                console.log("Found an authorized account:", account);
                setCurrentAccount(account)
            } else {
                console.log("No authorized account found")
            }
        } catch (error) {
            console.log(error);
        }
    }

    const connectWallet = async () => {
        try {

            if (!ethereum) {
                alert("Get MetaMask!");
                return;
            }

            const accounts = await ethereum.request({ method: "eth_requestAccounts" });

            console.log("Connected", accounts[0]);
            setCurrentAccount(accounts[0]);

        
        } catch (error) {
            console.log(error)
        }
    }

    useEffect(() => {
        checkIfWalletIsConnected();
        
      }, [])

    let view = null
    let viewWalletStatus = null

    if (!currentAccount ){

        viewWalletStatus = <button className="kviMVi" onClick={connectWallet}>Connect Wallet</button>
    
    } else {
        viewWalletStatus = 
        <button className="kviMVi"><b>Connected:</b> {String(currentAccount).substring(0, 6) + "..." + String(currentAccount).substring(38)}</button>
        view = <button className="kviMVi" onClick={handleGetVRF}>Get VRF</button>

    }

        // const ugly ='BigNumber {_hex: '0x9104a66a4a3ae735473d1ad9179ba09e13571f46c0345cb831ff7c3aa2dd2b0c', _isBigNumber: true}'
        //console.log(arrayRandomNumbers)
    return(
        <React.Fragment>
            <div>
                {viewWalletStatus}
            </div>
                {view}
            <div>
                {arrayRandomNumbers.map((singleItem, index) => {
                    return (
                    <div key={index} style={{ backgroundColor: "OldLace", marginTop: "16px", padding: "8px" }}>
                        <div>Number {index}: {singleItem % 100}</div>

                    </div>)
                })}
            </div>
          </React.Fragment>
        // <form onSubmit={handleFormSubmit}>
        //     <input
        //     type='text'
        //     name='prayer_request'
        //     placeholder='Enter your prayer here' 
        //     required
        //     />&nbsp;
        //     <button className="waveButton">🙏Pray for me!</button>
        // </form>


    
    // {!currentAccount && (
    // <button className="waveButton" onClick={connectWallet}>
    // Connect Wallet
    // </button>
    // )}



    )



  
}


export default Controller