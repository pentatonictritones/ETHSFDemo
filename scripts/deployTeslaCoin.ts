import { BigNumber } from "ethers";
import { ethers, upgrades } from "hardhat"

async function main() {
const TestCoin = await ethers.getContractFactory("TestCoin");

  let testUSDC = await upgrades.deployProxy(TestCoin,
    [
        "Test USDC",
        "tUSDC"
    ],
        { initializer: 'initialize', kind: 'uups' }
);

    console.log(testUSDC.address);


    let teslaCoin = await ethers.getContractAt("TestCoin", "0xD6763232ebbc58a61E7a5E8bb0B3d36AF64D3a4B")
    let babaCoin = await ethers.getContractAt("TestCoin", "0x7aC6c8Ca0118F7dB8b339d0f8Bc83b39e38183F7")
    let dadaCoin = await ethers.getContractAt("TestCoin", "0xF80A0a51033E003bbD79ACb3B3180cd7316EcA11")
    await teslaCoin.changeUpgradeStatus(true)
    await babaCoin.changeUpgradeStatus(true)
    await dadaCoin.changeUpgradeStatus(true)


    await upgrades.upgradeProxy(teslaCoin.address, TestCoin)
    await upgrades.upgradeProxy(babaCoin.address ,TestCoin)
    await upgrades.upgradeProxy(dadaCoin.address, TestCoin)

//   let teslaCoin = await upgrades.deployProxy(TestCoin,
//     [
//         "Collateralized Tesla",
//         "cTSLA"
//     ],
//         { initializer: 'initialize', kind: 'uups' }
// );

//     console.log(teslaCoin.address);


//   let appleCoin = await upgrades.deployProxy(TestCoin,
//     [
//         "Collateralized Apple",
//         "cAAPL"
//     ],
//         { initializer: 'initialize', kind: 'uups' }
// );

//     console.log(appleCoin.address);


//   let gmeCoin = await upgrades.deployProxy(TestCoin,
//     [
//         "Collateralized GameStop",
//         "cGME"
//     ],
//         { initializer: 'initialize', kind: 'uups' }
// );

//     console.log(gmeCoin.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });