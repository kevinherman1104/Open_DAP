import React, { useEffect, useState } from "react";
import logo from "../../assets/logo.png";
import {Actor, HttpAgent} from "@dfinity/agent"
import {idlFactory} from"../../../declarations/nft" // for our back end (MOTOKO) to communicate with the JavaScript
import {idlFactory as tokenIdlFactory} from "../../../declarations/token";// for our back end (Token Project) to communicate with the JavaScript
import {Principal} from "@dfinity/principal"
import Button from "./Button";
import { opend } from "../../../declarations/opend/index";
import CURRENT_USER_ID from "../index";
import PriceLabel from "./PriceLabel";
import { token } from "../../../declarations/token/index";


function Item(props) {

  const [name, setName] = useState();
  const [owner, setOwner] = useState();
  const [image, setImage] = useState();
  const [button, setButton] = useState();
  const [priceInput, setPrinceInput] = useState();
  const [loaderHidden, setLoaderHidden] = useState(true);
  const [blur, setBlur] = useState();
  const [sellStatus, setSellStatus] = useState();
  const [priceLabel, setPriceLabel] = useState();
  const [shouldDisplay, setDisplay] = useState(true);

  //Holds the NFT id of each item
  const id = props.id;

  //make request to canister using HTTP method from the localhost
  const localHost = "http://localhost:8080/";
  const agent = new HttpAgent({host: localHost});

  //TODO: remove the following line, when deploying live 
  agent.fetchRootKey();

  // Variable to store the NFT from the id passed to id props of Item component
  let NFTActor;

  //Async function to load the NFTs based on the idlFactory we imported above
  async function loadNFT(){
    NFTActor = await Actor.createActor(idlFactory, {
      agent,
      canisterId: id,
    });

    //Setting the property of each NFT Item retrieved from the NFTActor variable
    const name = await NFTActor.getName();
    setName(name);

    const owner = await NFTActor.getOwner();
    setOwner(owner.toText());

    const imageData =  await NFTActor.getContent();
    const imageContent = new Uint8Array(imageData);
    const image = URL.createObjectURL(new Blob([imageContent.buffer], { type: "image/png" })); // to create image URL for our converted NAT8 array from backend
    setImage(image);

    //Checking whether the Item is listed as collection or listed for sell
    if(props.role == "collection"){
      const nftIsListed = await opend.isListed(props.id);
    
      if(nftIsListed){
        setOwner("OpenD");
        setBlur({filter: "blur(4px)"});
        setSellStatus("Listed")

      } else{
        setButton(<Button handleClick={handleSell} text={"Sell"}/>)
      }
    }else if(props.role == "discover"){
      const originalOwner = await opend.getOriginalOwner(props.id);
      if(originalOwner.toText() != CURRENT_USER_ID.toText()){
        setButton(<Button handleClick={handleBuy} text={"Buy"}/>)
      }

      const price =  await opend.getListedNFTPrice(props.id);
      setPriceLabel(<PriceLabel sellPrice={price.toString()}/>)

      
    }
    

  }
  // Use Effect method to call the loadNFT function
  useEffect(()=> {
    loadNFT();

  }, []);

  let price;
  //function to show the input for the user
  function handleSell(){
    // console.log("Sell Item!")
    setPrinceInput(<input
      placeholder="Price in DANG"
      type="number"
      className="price-input"
      value={price}
      onChange={(e) => price = e.target.value}
    />);

    
    setButton(<Button handleClick={sellItem} text={"Confirm"} />)
    
  }

  //function to handle sell item within the backend
  async function sellItem(){
    setBlur({filter: "blur(4px)"});
    setLoaderHidden(false);

    const listingResult = await opend.listItem(props.id, Number(price));
    console.log(listingResult + "Listing");

    //Transfer Process
    if (listingResult == "Success"){
      const OpenDId = await opend.getOpenDCanisterID();
      const transferResult = await NFTActor.transferOwnership(OpenDId);
      console.log(transferResult);

      if(transferResult == "Success"){
        setLoaderHidden(true);
        setButton();
        setPrinceInput();
        setOwner("OpenD");
        setSellStatus("Listed")
      }

    }

  }

  //function to handle buy button gets clicked by user
  async function handleBuy(){
    // console.log("Buy!")
    setLoaderHidden(false);

    //create an instance of the token actor so we can make use of the transfer function
    const tokenActor = await Actor.createActor(tokenIdlFactory, {
      agent,
      canisterId: Principal.fromText("q4eej-kyaaa-aaaaa-aaaha-cai"), //token ID retrieved from the Token Project
    });

    const sellerId = await opend.getOriginalOwner(props.id);
    const itemPrice = await opend.getListedNFTPrice(props.id)

    //Making use of Token Project's Transfer method
    const resultTransfer = await tokenActor.transfer(sellerId, itemPrice);

    if (resultTransfer == "Success"){
      //Transfer the ownership
      const result = await opend.completePurchase(props.id, sellerId, CURRENT_USER_ID);
      console.log("Purchase: " + result)
      setLoaderHidden(true);
      setDisplay(false)
    }

  }

  
  return (
    <div style={{display: shouldDisplay ? "inline" : "none"}} className="disGrid-item">
      <div className="disPaper-root disCard-root makeStyles-root-17 disPaper-elevation1 disPaper-rounded">
        <img
          className="disCardMedia-root makeStyles-image-19 disCardMedia-media disCardMedia-img"
          src={image}
          style = {blur}
        />
        <div hidden={loaderHidden} className="lds-ellipsis">
          <div></div>
          <div></div>
          <div></div>
          <div></div>
        </div>
        <div className="disCardContent-root">
          {priceLabel}
          <h2 className="disTypography-root makeStyles-bodyText-24 disTypography-h5 disTypography-gutterBottom">
            {name}
            <span className="purple-text"> {sellStatus}</span>
          </h2>
          <p className="disTypography-root makeStyles-bodyText-24 disTypography-body2 disTypography-colorTextSecondary">
            Owner: {owner}
          </p>
          {priceInput}
          {button}
        </div>
      </div>
    </div>
  );
}

export default Item;
