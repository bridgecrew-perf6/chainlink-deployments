import React, { useEffect, useState } from "react";
import { ethers } from "ethers";
import abi from './../../utils/ChainlinkAnyApi.json';

const Controller = () => {

    const { ethereum } = window
    const [currentAccount, setCurrentAccount] = useState("");
    // const [volumeData, setVolumeData] = useState("");
    const [volumeDataFormatEthers, setVolumeDataFormatEthers] = useState("");
    const [volumeDataDirect, setVolumeDataDirect] = useState("");

    const contractAddress = "0xe106A4E201e638610b0CcED7981158b1bba8A228"; //Any API ovan Contract
    const contractABI = abi.abi;

    const provider = new ethers.providers.Web3Provider(ethereum); //fix 1
    const signer = provider.getSigner();
    const contract = new ethers.Contract(contractAddress, contractABI, signer);



    const handleGetVolumeData = async ()=>{

        await contract.requestVolumeData();

         const temp = await contract.volume()

         console.log(temp)

         const getVolumeFormatEthers = ethers.utils.formatEther(temp)
        //  const getVolume = parseInt(temp)
          
        // setVolumeData(getVolume)
        setVolumeDataFormatEthers(getVolumeFormatEthers)
        
        
        const response = await fetch("https://min-api.cryptocompare.com/data/pricemultifull?fsyms=ETH&tsyms=USD")
        const data = await response.json()
        setVolumeDataDirect(data.RAW.ETH.USD.VOLUME24HOUR)
          
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
        view = <button className="kviMVi" onClick={handleGetVolumeData}>Get Volume Data</button>

    }
  
          // const ugly ='BigNumber {_hex: '0x9104a66a4a3ae735473d1ad9179ba09e13571f46c0345cb831ff7c3aa2dd2b0c', _isBigNumber: true}'
        console.log(volumeDataFormatEthers)
        console.log(volumeDataDirect)
    return(
        <React.Fragment>
            <div className="connectButton">
            {viewWalletStatus}
            </div>
            {view}
                <div style={{ backgroundColor: "OldLace", marginTop: "16px", padding: "8px" }}>
                    {/* <div>Volume Data On Chain JS Native Parse Int Conversion: {volumeData}</div> */}
                    <div>Volume Data <strong>Format Ethers Big Number Conversion</strong>: {volumeDataFormatEthers}</div>
                    <div>Volume Data <strong>Off Chain</strong>: {volumeDataDirect}</div>
                    
                </div>
        </React.Fragment>
    )
  
  
    
  }
  
  
  export default Controller