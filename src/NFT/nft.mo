import Debug "mo:base/Debug";
import Principal "mo:base/Principal";


//Each time we create new instance of NFT a new principal ID will be assigned to the corresponding NFT
actor class NFT(name: Text, owner: Principal, content: [Nat8]) = this{
    
    let itemName = name;
    let nftowner =  owner;
    let imageBytes = content;

    //function created which is going to allow us to get hold of the NFT name.
    public query func getName () : async Text{
        return itemName;
    };

    //function created which is going to allow us to get hold of the NFT owner Principal.
     public query func getOwner () : async Principal{
        return nftowner;
    };

    //function created which is going to allow us to get hold of the NFT image data.
     public query func getContent () : async [Nat8]{
        return imageBytes;
    };

     //function created which is going to allow us to get hold of the canister ID.
    public query func getCanisterId(): async Principal{
        return Principal.fromActor(this); //returns the principal of the corresponding actor (which points to the NFT actor class)
    }
   

};