import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { BigNumber } from "ethers";
import { parseUnits } from "ethers/lib/utils";
import { ethers, network } from "hardhat"
import { DCAContract, IERC20MetadataUpgradeable } from "../typechain";

describe("Testers ", function () {
    let DCAContract : DCAContract
    let signers: SignerWithAddress[]
    let usdc: IERC20MetadataUpgradeable
    before(async function () {
                //We are forking Polygon mainnet, please set Alchemy key in .env
                await network.provider.request({
                    method: "hardhat_reset",
                    params: [{
                        forking: {
                            enabled: true,
                            jsonRpcUrl: process.env.POLYGON_FORKING_URL as string,
                            //you can fork from last block by commenting next line
                        },
                    }, ],
                });
        

    });

    beforeEach(async function () {
        signers = await ethers.getSigners();
        const DCAContractFactory = await ethers.getContractFactory("DCAContract");

        const ibAlluoUSD = "0xC2DbaAEA2EfA47EBda3E572aa0e55B742E408BF6";
        const ibAlluoETH = "0xc677B0918a96ad258A68785C2a3955428DeA7e50";
        const ricochetDCAContract = "0xD0a8aeD52e80F99F7daDa1E22369B707437b6B34"
        DCAContract = await DCAContractFactory.deploy(ibAlluoUSD, ibAlluoETH, ricochetDCAContract)
        console.log(DCAContract.address);
        let usdcWhale = await ethers.getImpersonatedSigner("0xf89d7b9c864f589bbf53a82105107622b35eaa40");
        usdc = await ethers.getContractAt("IERC20MetadataUpgradeable", "0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174")
        await usdc.connect(usdcWhale).transfer(signers[0].address, parseUnits("100000", 6))
        await usdc.approve(DCAContract.address, ethers.constants.MaxUint256);
    });

    describe('Test All functions', function () {

        it("test deposit", async function () {
            await DCAContract.getIbAlluoFrom(parseUnits("100",6), usdc.address)
            console.log(await DCAContract.checkBalances());
        });
        it("test create flow", async function () {
            await DCAContract.getIbAlluoFrom(parseUnits("100",6), usdc.address)
            await DCAContract.startDCAStream("1000000000")
        });


})});
