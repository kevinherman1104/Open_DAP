import Debug "mo:base/Debug";
import Principal "mo:base/Principal";


//Each time we create new instance of NFT a new principal ID will be assigned to the corresponding NFT
actor class NFT(name: Text, owner: Principal, content: [Nat8]){
    
    let itemName = name;
    let nftowner =  owner;
    let imageBytes = content;

    public query func getName () : async Text{
        return itemName;
    };

     public query func getOwner () : async Principal{
        return nftowner;
    };

     public query func getContent () : async [Nat8]{
        return imageBytes;
    };
    

};