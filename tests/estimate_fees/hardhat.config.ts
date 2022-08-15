/** @type import('hardhat/config').HardhatUserConfig */
import "@shardlabs/starknet-hardhat-plugin";

module.exports = {
  solidity: "0.8.9",
  starknet: {
    venv: "~/.cairo_venv", // venv to use for compiling
    network: "integrated-devnet",
  },
  networks: {
    integratedDevnet: {
      url: "http://127.0.0.1:5050",
      venv: "~/.cairo_venv", // venv to use to launch integrated devnet when needed
    },
  },
  paths: {
    // Defaults to "contracts" (the same as `paths.sources`).
    starknetSources: "../../contracts/",

    // Same purpose as the `--cairo-path` argument of the `starknet-compile` command
    // Allows specifying the locations of imported files, if necessary.
    cairoPaths: ["../../contracts/"],
  },
};
