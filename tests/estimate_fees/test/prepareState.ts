import { starknet } from "hardhat";
import { Account } from "hardhat/types";

import { deployStarknetContract, dumpState, loadState } from "./utils";

describe("Preparing devnet state", function () {
  this.timeout(0);

  it("Dumping devnet state...", async function () {
    const accounts: Account[] = [];
    for (let index = 0; index < 400; index++) {
      console.log(`Deploying account ${index + 1}/400...`);
      const account = await starknet.deployAccount("OpenZeppelin");
      accounts.push(account);
    }
    console.log("Deploying metadata...");
    const sampleMetadata = await deployStarknetContract(
      "tests/sample_pxl_metadata_contract.cairo"
    );
    console.log("Deploying PXL ERC-721...");
    const pixelERC721 = await deployStarknetContract(
      "contracts/pxls/PixelERC721/PixelERC721.cairo",
      {
        name: 1350069363,
        symbol: 1347963987,
        m_size: { high: 0, low: 20 },
        owner: accounts[0].address,
        pxls_1_100_address: sampleMetadata.address,
        pxls_101_200_address: sampleMetadata.address,
        pxls_201_300_address: sampleMetadata.address,
        pxls_301_400_address: sampleMetadata.address,
      }
    );
    console.log("Deploying Pixel Drawer...");
    const pixelDrawer = await deployStarknetContract(
      "contracts/pxls/PixelDrawer/PixelDrawer.cairo",
      {
        owner: accounts[0].address,
        pixel_erc721_address: pixelERC721.address,
        max_colorizations: 40,
      }
    );
    await dumpState(accounts, pixelERC721, pixelDrawer);

    for (let index = 0; index < 400; index++) {
      console.log(`Minting pxl ${index + 1} / 400`);
      await accounts[index].invoke(pixelERC721, "mint", {
        to: accounts[index].address,
      });
      if ((index + 1) % 50 === 0) {
        await dumpState(accounts, pixelERC721, pixelDrawer);
      }
    }

    await dumpState(accounts, pixelERC721, pixelDrawer);
  });
});
