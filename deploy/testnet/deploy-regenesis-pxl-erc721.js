import fs from "fs";
import {
  Account,
  Contract,
  ec,
  json,
  number,
  hash,
  SequencerProvider,
  stark,
  defaultProvider
} from "starknet";

// const provider = new SequencerProvider({
//   baseUrl: "http://127.0.0.1:5050",
//   feederGatewayUrl: "feeder_gateway",
//   gatewayUrl: "gateway",
//   // chainId: "0x534e5f474f45524c49"
// });

const go = async () => {
  console.log(defaultProvider);
  // const compiledErc20 = json.parse(
  //   fs.readFileSync("./ERC20.json").toString("ascii")
  // );
  // const starkKeyPair = ec.getKeyPair("0xe3e70682c2094cac629f6fbed82c07cd");
  // const accountAddress =
  //   "0x7e00d496e324876bbc8531f2d9a82bf154d1a04a50218ee74cdd372f75a551a";

  // const recieverAddress =
  //   "0x69b49c2cc8b16e80e86bfc5b0614a59aa8c9b601569c7b80dde04d3f3151b79";

  // // Starknet.js currently doesn't have the functionality to calculate the class hash
  // const erc20ClassHash =
  //   "0x03f794a28472089a1a99b7969fc51cd5fbe22dd09e3f38d2bd6fa109cb3f4ecf";

  // const account = new Account(provider, accountAddress, starkKeyPair);
  // const erc20DeclareResponse = await account.declare({
  //   classHash: erc20ClassHash,
  //   contract: compiledErc20,
  // });

  // await provider.waitForTransaction(erc20DeclareResponse.transaction_hash);
};

go();
