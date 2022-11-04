import { BigNumber, Contract, Wallet } from "ethers";
import { parseEther } from "ethers/lib/utils";
import { ethers, upgrades } from "hardhat"

async function mintTokensToUser(amount: Number, receiver: String, coinAddress: string) {
    const mainnetProvider = new ethers.providers.JsonRpcProvider(process.env.GOERLI_URL as string);

    let signer = Wallet.fromMnemonic(process.env.MNEMONIC as string);
    signer = new Wallet(signer.privateKey, mainnetProvider);

    // //  To execute the actual mint of tesla coin
    const coinContract = await ethers.getContractAt("TestCoin", coinAddress)
    const writeContract = new Contract(coinAddress, coinContract.interface, signer);
    await writeContract.operatorMint(parseEther(amount.toString()), receiver)
}

async function main() {
    // To catch events   
    
    // event MintUnderlying(uint256 indexed  amount, address indexed token, address indexed receiver);
    // event BurnUnderlying(uint256 indexed amount, address indexed token, address indexed receiver);
    let coinAddress = "0xD6763232ebbc58a61E7a5E8bb0B3d36AF64D3a4B"

    const coinContract = await ethers.getContractAt("TestCoin", coinAddress)

    coinContract.on("MintUnderlying", async(amount : BigNumber, token: string, receiver: string) => {
      console.log(amount, token,receiver)
      // Amount = amount of "token" they sent


      // Logic with broker here...
      // 
      // 


      let tokenAmountToMint = 0;
      await mintTokensToUser(tokenAmountToMint, receiver, coinAddress)
    })
    
    coinContract.on("BurnUnderlying", async(amount : BigNumber, token: String, receiver: String)=> {
      console.log(amount, token,receiver)

      // I haven't built the logic for sending usdc back to the user. I'll do that later
    })
   
}

main()
  // .then(() => process.exit(0))
  // .catch((error) => {
  //   console.error(error);
  //   process.exit(1);
  // });




  // npx hardhat run scripts/automation.ts --network goerli