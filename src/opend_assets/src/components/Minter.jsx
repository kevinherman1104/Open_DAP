import React, { useState } from "react";
import { useForm } from "react-hook-form";
import {opend} from "../../../declarations/opend"
import Item from "./Item";

function Minter() {

  //variable to conatin the user input in the form indicating nft name
  const {register, handleSubmit} = useForm();
  //variable to contain nft principal that is going to be created later on
  const [nftPrincipal, setNFTPrincipal] = useState("");
  //variables for hidden loader when user tap on mint NFT
  const [loaderHidden, setLoaderHidden] = useState(true);

  async function onSubmit(data){
    setLoaderHidden(false);

    const name = data.name;
    const image = data.image[0]; 

    // arrayBuffer (returns Promise) is used to represent generic, fixed length raw binary buffer data, which will be used to store our image file in nat8 format array
    const imageByteData = [...new Uint8Array(await image.arrayBuffer())]; 


    const newNFTID  = await opend.mint(imageByteData, name); //will return in form of principal from the main.mo
    setNFTPrincipal(newNFTID);

    setLoaderHidden(true);
    console.log(newNFTID.toText());



  }

  //Checks whether the new nftPrincipal has been created when minting new NFT. If not it will be "" and dusplays the mint page
  if (nftPrincipal == ""){
    return (
      <div className="minter-container">
        <div hidden={loaderHidden} className="lds-ellipsis">
        <div></div>
        <div></div>
        <div></div>
        <div></div>
      </div>
        <h3 className="makeStyles-title-99 Typography-h3 form-Typography-gutterBottom">
          Create NFT
        </h3>
        <h6 className="form-Typography-root makeStyles-subhead-102 form-Typography-subtitle1 form-Typography-gutterBottom">
          Upload Image
        </h6>
        <form className="makeStyles-form-109" noValidate="" autoComplete="off">
          <div className="upload-container">
            <input
              {...register("image", {required: true})}
              className="upload"
              type="file"
              accept="image/x-png,image/jpeg,image/gif,image/svg+xml,image/webp"
            />
          </div>
          <h6 className="form-Typography-root makeStyles-subhead-102 form-Typography-subtitle1 form-Typography-gutterBottom">
            Collection Name
          </h6>
          <div className="form-FormControl-root form-TextField-root form-FormControl-marginNormal form-FormControl-fullWidth">
            <div className="form-InputBase-root form-OutlinedInput-root form-InputBase-fullWidth form-InputBase-formControl">
              <input
                {...register("name", {required: true})}
                // Using the useform to copy the user input and turn it into object with the property "name"
                placeholder="e.g. CryptoDunks"
                type="text"
                className="form-InputBase-input form-OutlinedInput-input"
              />
              <fieldset className="PrivateNotchedOutline-root-60 form-OutlinedInput-notchedOutline"></fieldset>
            </div>
          </div>
          <div className="form-ButtonBase-root form-Chip-root makeStyles-chipBlue-108 form-Chip-clickable">
            <span onClick={handleSubmit(onSubmit)} className="form-Chip-label">Mint NFT</span> 
            {/* /* When Mint NFT button clicked triggers the handlesubmit which calls onSubmit to take the value of NFT name that user inputs  */}
          </div>
        </form>
      </div>
    );
// If new NFT principal has been created for the newly minted NFT then this code will be executed which will show the NFT newly added
  }else{ 
    return(
    <div className="minter-container">
    <h3 className="Typography-root makeStyles-title-99 Typography-h3 form-Typography-gutterBottom">
      Minted!
    </h3>
    <div className="horizontal-center">
      <Item id={nftPrincipal.toText()}/>
    </div>
  </div>

    )
  

  }
  
}

export default Minter;
