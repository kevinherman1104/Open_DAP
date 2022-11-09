import Principal "mo:base/Principal";
import NFTActorClass "../NFT/nft";
import Cycles "mo:base/ExperimentalCycles";
import Debug "mo:base/Debug";
import HashMap "mo:base/HashMap";
import List "mo:base/List"
// import NFT "../NFT/nft";

actor OpenD {

    //Creating Hashmap to store all the NFTS along with their owner in form of principal ID, Principal.equal ceks for duplication, Principal.hash Hashes the ID that will be stored in the hashmap.
    var mapOfNFTs = HashMap.HashMap<Principal, NFTActorClass.NFT>(1, Principal.equal, Principal.hash);
    
    //Creating Hashmap to store all the Owner of the NFTs, so we can later on map them within their lists of NFTs 
    // (note that List is going to contain list of canister ID which represents each NFTs)
    // So user will have more than one NFTs with different canister IDs
    var mapOfOwners = HashMap.HashMap<Principal, List.List<Principal>>(1, Principal.equal, Principal.hash);



    //shared keyword is used for us to get the identity of the user who called the mint functionn, in the form of principal data type
    public shared(msg) func mint(imgData: [Nat8], name: Text): async Principal{
        let owner: Principal = msg.caller;

        //Adding cycles for each time newNFT is created, those cycles will come from this main canister and be allocated for the next canister that gets created.
        //By default costs 100 billion cycles to create a new canister
        //500 million cycles added in order to keep it up and running

        Debug.print(debug_show(Cycles.balance()));
        Cycles.add(100_500_000_000);

        //Creating new canister (which will eat up the cycle we specified above)
        let newNFT = await NFTActorClass.NFT(name, owner, imgData);
        Debug.print(debug_show(Cycles.balance()));

        let newNFTPrincipal: Principal = await newNFT.getCanisterId();

        //Adding new item of newly minted NFTs to the hashmap
        mapOfNFTs.put(newNFTPrincipal, newNFT);

        //Adding new owner when minting new NFTs into the mapOfOwners Hashmap, by calling the correponding function below
        addToOwnershipMap(owner, newNFTPrincipal);

        return newNFTPrincipal;





    };

    //Map the ownership with their NFTS
    private func addToOwnershipMap(owner: Principal, nftId: Principal){

        //Conditional statement to handle null user, or we can say not existing owner yet (new owner that minted new NFTs)
        // And if not exist return empty list to the variable
        // If exist return the list which contains canister ID (that represent NFTs) that we get from the mapOfOwners hashmap, to the ownedNFTS variable
        var ownedNFTs :List.List<Principal> = switch (mapOfOwners.get(owner)){
            case null List.nil<Principal>();
            case (?result) result;
        };

        //Take the previous version of that list (ownedNFTs), added the new nftID and then set that list to equal the new updated version of the list.
        ownedNFTs := List.push(nftId, ownedNFTs);

        // Put the owner and the newly/updated version of the list
        mapOfOwners.put(owner, ownedNFTs);



    };

    //Method to fetch that list of IDs and turn it into an array that can be used on the frontend later on.
    public query func getOwnedNFTs(user: Principal): async [Principal] {
         //Conditional statement to handle null user
        var userNFTs :List.List<Principal> = switch (mapOfOwners.get(user)){
            case null List.nil<Principal>();
            case (?result) result;
        };

        return List.toArray(userNFTs);

    }
 
};
