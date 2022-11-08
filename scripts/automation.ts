import { BigNumber, Contract, Wallet } from "ethers";
import { parseEther } from "ethers/lib/utils";
import { ethers, upgrades } from "hardhat"

async function main() {
    let coinAddress = "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48"
    const coinContract = await ethers.getContractAt("TestCoin", coinAddress)

    let filterTo = coinContract.filters.Transfer(null, null);
   
    // Last 20 blocks
    console.log(await coinContract.queryFilter(filterTo, -20));


    coinContract.on("Transfer", async(from : string, to: string, value: BigNumber) => {

      console.log(from, to,value)
      // Amount = amount of "token" they sent

    })   
}

main()

// Uncomment this if you want it to exit after a call. needs to be commented for the listener though.
  // .then(() => process.exit(0))
  // .catch((error) => {
  //   console.error(error);
  //   process.exit(1);
  // });




  // npx hardhat run scripts/automation.ts --network mainnet