import { Account } from "@shardlabs/starknet-hardhat-plugin/dist/src/account";
import { DeployOptions } from "@shardlabs/starknet-hardhat-plugin/dist/src/types";
import { readFileSync, writeFileSync } from "fs";
import { starknet } from "hardhat";
import { StringMap, StarknetContract } from "hardhat/types";
import path from "path";

export const getStarknetContractPath = (contractPath: string) =>
  path.resolve(`../../${contractPath}`);

export const getStarknetContractFactory = (contractPath: string) =>
  starknet.getContractFactory(getStarknetContractPath(contractPath));

export const getRandomInt = (max: number) => {
  return Math.floor(Math.random() * max);
};

export const deployStarknetContract = async (
  contractPath: string,
  constructorArguments?: StringMap,
  options?: DeployOptions
): Promise<StarknetContract> => {
  const factory = await getStarknetContractFactory(contractPath);
  const contract = await factory.deploy(constructorArguments, options);
  return contract;
};

export const loadStarknetContract = async (
  contractPath: string,
  address: string
): Promise<StarknetContract> => {
  const factory = await getStarknetContractFactory(contractPath);
  const contract = factory.getContractAt(address);
  return contract;
};

export const dumpAddresses = (
  accounts: Account[],
  pixelERC721: StarknetContract,
  pixelDrawer: StarknetContract
) => {
  console.log("Dumping addresses...");
  writeFileSync(
    path.resolve("./test/addresses.json"),
    JSON.stringify({
      accounts: accounts.map((a) => ({
        address: a.address,
        privateKey: a.privateKey,
      })),
      pixelDrawer: pixelDrawer.address,
      pixelERC721: pixelERC721.address,
    })
  );
};

export const dumpState = async (
  accounts: Account[],
  pixelERC721: StarknetContract,
  pixelDrawer: StarknetContract
) => {
  console.log("Dumping state...");
  await starknet.devnet.dump("./test/devnet-state");
  dumpAddresses(accounts, pixelERC721, pixelDrawer);
  console.log("DONE");
};

export const loadState = async () => {
  console.log("Loading state...");
  await starknet.devnet.load("./test/devnet-state");
  console.log("Loading addresses...");
  const addresses = JSON.parse(readFileSync("./test/addresses.json", "utf-8"));
  const accounts: Account[] = [];
  for (let index = 0; index < addresses.accounts.length; index++) {
    const account = await starknet.getAccountFromAddress(
      addresses.accounts[index].address,
      addresses.accounts[index].privateKey,
      "OpenZeppelin"
    );
    accounts.push(account);
  }

  const pixelERC721 = await loadStarknetContract(
    "contracts/pxls/PixelERC721/PixelERC721.cairo",
    addresses.pixelERC721
  );

  const pixelDrawer = await loadStarknetContract(
    "contracts/pxls/PixelDrawer/PixelDrawer.cairo",
    addresses.pixelDrawer
  );

  console.log("Setting devnet time");
  await starknet.devnet.setTime(Math.floor(new Date().getTime() / 1000));

  return { accounts, pixelERC721, pixelDrawer };
};
