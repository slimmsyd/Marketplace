import { useState, useEffect, useRef } from "react"
import { Contract, ethers, providers } from "ethers"
import {useRouter} from 'next/router';
import Web3Modal, { setLocal } from 'web3modal';
import Image from 'next/image'
import axios from 'axios';
import { NFT_ADDRESS, MARKET_ADDRESS, NFT_ADDRESS_ABI, MARKET_ADDRESS_ABI } from '../constants';
import Nav from "./Nav";
import { create as ipfsHttpClient, uint8arrays  } from 'ipfs-http-client'


export default function CreateItem() { 
    const [fileUrl, setFileUrl] = useState(null);
    const [formInput, updateFormInput] = useState({price: "", name: "", description : ""});
    const [walletConnect, setWalletConnected] = useState(false);
    const [accountAddress, setAccountAddress] = useState('')
    const [nft, setNft] = useState({});
    const [marketPlace, setMarketPlace] = useState({})
    const [loading, setLoading] = useState(true);
    const web3modalref = useRef();
    const router = useRouter();
    
    //load contract 
    const loadContract = async() => { 
        const signer = await getProviderOrSigner(true)
        const marketplace = new Contract(MARKET_ADDRESS,MARKET_ADDRESS_ABI, signer );
        setMarketPlace(marketplace);
        const nft = new Contract(NFT_ADDRESS, NFT_ADDRESS_ABI, signer);
        setNft(nft);
        setLoading(false);
    }

    async function Connect() { 
        await getProviderOrSigner()
        setWalletConnected(true);

    }
    useEffect(() => { 
        if(!walletConnect) { 
          web3modalref.current = new Web3Modal({
            network: "matic",
            providerOptions: {},
            disableInjectedProvider: false,
          })
        }
        Connect()
    
      },[])
      const getProviderOrSigner = async(needSigner = false) => { 
        const provider = await web3modalref.current.connect();
        const web3provider = new providers.Web3Provider(provider);
    
        const signer =  web3provider.getSigner();
        const address = await signer.getAddress()
        setAccountAddress(address)
       
    
        const {chainId} = await web3provider.getNetwork();
        if (chainId !== 80001) { 
            window.alert("You are on the wrong Network")
        }
    
    
    
        if(needSigner) { 
          const signer = web3provider.getSigner();
          return signer
        }
        return web3provider;
      };

      async function onChange(e) { 
        const file = e.target.files[0];
        try { 
            const added = await client.add(
                file,
                {
                    progress: (prog) => console.log(`recieved: ${prog}`)
                }
            );
            const url = `https://ipfs.infuria.io/ipfs/${added.path}`
            console.log(url);
        }catch(e) { 
          console.error(e.message)
    }
    };


      //upload files to IPFS
      const uploadToIPFS = async(e) => { 
          const file = e.target.files[0]
          //check if legimite file was inputted
          if(typeof file !== "undefined") {
              try { 
                const data = await client.add(file);
                console.log(data);
                setFileUrl(`https://infura.io/ifps/${data.path}`)
              }catch(error) { 
                  console.error(error)
              }
          }
      }


      
      //createNFT function
      const createNFT = async() => { 
        const {name, description, price}  = formInput;
        if(!name || !description || !price || !fileUrl) return;
        try { 
            const data = JSON.stringify({
                name, description, image:fileUrl
            });
            mintThenList(data);
        }catch(error) { 
            console.error(error);
        }
      }

      const mintThenList = async(result) => { 
          const uri = `https://ipfs.infura.io/ipfs/${result.path}`
          //mint nft 
          await(await nft.mint(uri).wait());
          //get tokenID of new nft 
          const id = nft.tokenCount();
          //approve marketplace to spend nft 
          await(await nft.setApporvalForAll(marketPlace.address, true)).wait();
          //add nft to marketplace
          const listingPrice = ethers.utils.parseEther(formInput.price.toString());
         await(await marketPlace.makeItem(nft.address, id, listingPrice)).wait();
      }

    
    return (
        <>
        <Nav />
        <div className ="flex">
                <div className = 'flex flex_col'>
                    <input placeholder="Asset Name" className = "input" onChange={e => updateFormInput({...formInput, name: e.target.value })} />
                    <textarea placeholder="Asset Description" className = "textArea" onChange={e => updateFormInput({...formInput, description: e.target.value})} />
                    <input placeholder="Asset Price" className = "input" onChange={e => updateFormInput({...formInput, price: e.target.value })} />
                    <input type= "file" name = "Asset" className = "input" id ="file" onChange={uploadToIPFS}  />
                    {
                        fileUrl && (
                            <Image className = "img" width={350} height = {350} src= {fileUrl} />
                        )
                    }
                    <button onClick={createNFT} className ="btn"  >Create Sale</button>
                </div>
        </div>
        </>
    )


}
