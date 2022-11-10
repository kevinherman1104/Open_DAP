import Debug "mo:base/Debug";
import Principal "mo:base/Principal";


//Each time we create new instance of NFT a new principal ID will be assigned to the corresponding NFT
actor class NFT(name: Text, owner: Principal, content: [Nat8]) = this{
    
    private let itemName = name;
    private var nftOwner =  owner;
    private let imageBytes = content;

    //function created which is going to allow us to get hold of the NFT name.
    public query func getName () : async Text{
        return itemName;
    };

    //function created which is going to allow us to get hold of the NFT owner Principal.
     public query func getOwner () : async Principal{
        return nftOwner;
    };

    //function created which is going to allow us to get hold of the NFT image data.
     public query func getContent () : async [Nat8]{
        return imageBytes;
    };

     //function created which is going to allow us to get hold of the canister ID.
    public query func getCanisterId(): async Principal{
        return Principal.fromActor(this); //returns the principal of the corresponding actor (which points to the NFT actor class)
    };
    
    //function to transfer the ownership of one NFT owner to another
    public shared(msg) func transferOwnership(newOwner: Principal): async Text{
        //Verify whether the owner of the NFT is the one calling up the function
        if(msg.caller == nftOwner){
            nftOwner := newOwner;

            return "Success"

        }else{
            return "Error: Not initiated by NFT owner!"
        }

    }
   

};