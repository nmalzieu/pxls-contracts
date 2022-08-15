import { CallParameters } from "@shardlabs/starknet-hardhat-plugin/dist/src/account-utils";
import { Account, StarknetContract } from "hardhat/types";
import { dumpState, getRandomInt, loadState } from "./utils";

const colorizePixels = async (
  account: Account,
  pixelDrawer: StarknetContract,
  tokenId: number
) => {
  console.log(`Colorizing 40 pixels in 40 transactions for token ${tokenId}`);
  const colorizationsArray: CallParameters[] = [];

  for (let index = 0; index < 40; index++) {
    const pixelIndex = getRandomInt(400);
    const colorIndex = getRandomInt(95);
    colorizationsArray.push({
      toContract: pixelDrawer,
      functionName: "colorizePixels",
      calldata: {
        tokenId: { high: 0, low: tokenId },
        colorizations: [{ pixel_index: pixelIndex, color_index: colorIndex }],
      },
    });
  }
  await account.multiInvoke(colorizationsArray);
};

describe("Estimating fees", function () {
  this.timeout(0);

  it("Estimating colorization fees...", async function () {
    const { accounts, pixelDrawer, pixelERC721 } = await loadState();

    console.log("Launching initial round...");
    await accounts[0].invoke(pixelDrawer, "launchNewRoundIfNecessary", {
      theme: [1],
    });

    for (let index = 0; index < 400; index++) {
      await colorizePixels(accounts[index], pixelDrawer, index + 1);
      if ((index + 1) % 50) {
        await dumpState(accounts, pixelERC721, pixelDrawer);
      }
    }
  });
});
