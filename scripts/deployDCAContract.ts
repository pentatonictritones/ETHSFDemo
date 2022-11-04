import { BigNumber } from "ethers";
import { ethers } from "hardhat"

async function main() {
    const DCAContractFactory = await ethers.getContractFactory("DCAContract");

    const ibAlluoUSD = "0xC2DbaAEA2EfA47EBda3E572aa0e55B742E408BF6";
    const ibAlluoETH = "0xc677B0918a96ad258A68785C2a3955428DeA7e50";
    const ricochetDCAContract = "0x56aCA122d439365B455cECb14B4A39A9d1B54621"
    const DCAContract = await DCAContractFactory.deploy(ibAlluoUSD, ibAlluoETH, ricochetDCAContract)
    console.log(DCAContract.address);

    await DCAContract.deployed();
    console.log(DCAContract.address);

}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
});