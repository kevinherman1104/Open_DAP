import React, { useEffect, useState } from "react";
import logo from "../../assets/logo.png";
import {Actor, HttpAgent} from "@dfinity/agent"
import {idlFactory} from"../../../declarations/nft" // for our back end (MOTOKO) to communicate with the JavaScript
import {Principal} from "@dfinity/principal"
import Button from "./Button";
import { opend } from "../../../declarations/opend/index";


function Item(props) {

  const [name, setName] = useState();
  const [owner, setOwner] = useState();
  const [image, setImage] = useState();
  const [button, setButton] = useState();
  const [priceInput, setPrinceInput] = useState();
  const [loaderHidden, setLoaderHidden] = useState(true);
  const [blur, setBlur] = useState();
  const [sellStatus, setSellStatus] = useState();

  //Holds the NFT id of each item
  const id = props.id;

  //make request to canister using HTTP method from the localhost
  const localHost = "http://localhost:8080/";
  const agent = new HttpAgent({host: localHost});

  //TODO: remove the following line, when deploying live 
  agent.fetchRootKey();
  let NFTActor;

  //Async function to load the NFTs based on the idlFactory we imported above
  async function loadNFT(){
    NFTActor = await Actor.createActor(idlFactory, {
      agent,
      canisterId: id,
    });

    const name = await NFTActor.getName();
    setName(name);

    const owner = await NFTActor.getOwner();
    setOwner(owner.toText());

    const imageData =  await NFTActor.getContent();
    const imageContent = new Uint8Array(imageData);
    const image = URL.createObjectURL(new Blob([imageContent.buffer], { type: "image/png" })); // to create image URL for our converted NAT8 array from backend
    setImage(image);


    const nftIsListed = await opend.isListed(props.id);
    
    if(nftIsListed){
      setOwner("OpenD");
      setBlur({filter: "blur(4px)"});
      setSellStatus("Listed")

    } else{
      setButton(<Button handleClick={handleSell} text={"Sell"}/>)
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

  
  return (
    <div className="disGrid-item">
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
