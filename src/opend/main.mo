import Principal "mo:base/Principal";
import NFTActorClass "../NFT/nft";
import Cycles "mo:base/ExperimentalCycles";
import Debug "mo:base/Debug";
import HashMap "mo:base/HashMap";
import List "mo:base/List";
import Iter "mo:base/Iter";
// import NFT "../NFT/nft";

actor OpenD {

    // Custom type that represents each NFTs owner and Pric
    private type Listing = {
        itemOwner: Principal;
        itemPrice: Nat;


    };
    

    //Creating Hashmap to store all the NFTS along with their owner in form of principal ID, Principal.equal checks for duplication, Principal.hash Hashes the ID that will be stored in the hashmap.
    var mapOfNFTs = HashMap.HashMap<Principal, NFTActorClass.NFT>(1, Principal.equal, Principal.hash);
    
    //Creating Hashmap to store all the Owner of the NFTs, so we can later on map them within their lists of NFTs 
    // (note that List is going to contain list of canister ID which represents each NFTs)
    // So user will have more than one NFTs with different canister IDs
    var mapOfOwners = HashMap.HashMap<Principal, List.List<Principal>>(1, Principal.equal, Principal.hash);

    //Creating Hashmap to contain all the listed NFTs
    //The first parameter will be the principal ID of the listed NFTs
    //The second parameter will be a custom type, because it will hold a bunchof information
    var mapOfListings = HashMap.HashMap<Principal, Listing>(1, Principal.equal, Principal.hash);


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

        //Create an array that contains id of user NFTs retrieved from the list.
        return List.toArray(userNFTs);

    };

    //function created that will return list of NFTs Principal ID in form of a List
    public query func getListedNFTs(): async [Principal]{
        let ids = Iter.toArray(mapOfListings.keys());
        return ids;
    };

    public shared(msg) func listItem(id: Principal, price: Nat): async Text{
        //Verify whether the item exist or not based on the canister id, if yes assign it to the item variable
        var item: NFTActorClass.NFT = switch(mapOfNFTs.get(id)){
            case null return "NFT does not exist";
            case (?result) result;
        };

        //Get hold of the owner of the NFT that we are trying to list.
        
        let owner = await item.getOwner();

        //Verify the corresponding NFT that is going to be listed whether it has the real owner attached to the one's calling the function (msg.caller)
        if (Principal.equal(owner, msg.caller)){
            let newListing: Listing = {
                itemOwner = owner;
                itemPrice = price;
            };
            //listing the NFT into the hashmap of listings.
            mapOfListings.put(id, newListing);
            return "Success";

        } else{
            return "You do not own the NFT"
        }

    };

    //function to get the principal ID of the Canister
    public query func getOpenDCanisterID(): async Principal{
        return Principal.fromActor(OpenD);
    };

    //function to check whether the NFT has been listed or not
    public query func isListed(nftID: Principal): async Bool{
        if(mapOfListings.get(nftID) == null){
            return false;
        } else{
            return true;
        }
    };

    //function to get the original owner of the NFT
    public query func getOriginalOwner(id : Principal) : async Principal{
        var listing : Listing =  switch(mapOfListings.get(id)){
            case null return Principal.fromText("");
            case (?result) result;
        };

        return listing.itemOwner;

    };

    //function to get price of the listed NFT for sell
    public query func getListedNFTPrice(id : Principal) : async Nat{
        var listing : Listing =  switch(mapOfListings.get(id)){
            case null return 0;
            case (?result) result;
        };

        return listing.itemPrice;

    };


    //function to making sure that the purchase is success and transfer the ownership
    public shared(msg) func completePurchase(id: Principal, ownerId: Principal, newOwnerId: Principal): async Text{
        var purchasedNFT: NFTActorClass.NFT =  switch(mapOfNFTs.get(id)){
            case null return "NFT does not exist";
            case (?result) result;
            
        };
        
        let transferResult = await purchasedNFT.transferOwnership(newOwnerId);
        if (transferResult == "Success"){
            //Simply deletes the id of the purchased NFT from mapOfListings
            mapOfListings.delete(id);

            //declare list of ownedNFTs of the current user
            var ownedNFTS: List.List<Principal> = switch(mapOfOwners.get(ownerId)){
                case null List.nil<Principal>();
                case (?result) result;
            };


            // Loops through all of the list items, for each of the list items they get checked. 
            // And if that list item does not equal the ID of the NFT that's being purchased, then we're going to return true.
            // Otherwise, we're going to return false.
            // When true is returned, then that particular NFT id will get added to the new list.
            // And if it returns false, then that particular id will be omitted from the new list.
            //Simply takes the corresponding NFT and remove it from the list of ownedNFTs
            ownedNFTS := List.filter(ownedNFTS, func (listItemId: Principal): Bool{
                return listItemId != id;
            });

            addToOwnershipMap(newOwnerId, id);
            return "Success";

        } else{
            return transferResult;
        }

        


    };

    
 
};
