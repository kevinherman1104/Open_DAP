import Principal "mo:base/Principal";
import NFTActorClass "../NFT/nft";
import Cycles "mo:base/ExperimentalCycles";
import Debug "mo:base/Debug";

actor OpenD {

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

        return newNFTPrincipal;





    };
 
};
