const { exec, execSync } = require("child_process");

const contractRegex = /Contract address: (.*)/;

const execProtostarCommand = (protostarCommand) =>
  new Promise((resolve, reject) => {
    exec(protostarCommand, (err, stdout, stderr) => {
      if (err) {
        return reject(err);
      }
      return resolve(stderr);
    });
  });

const go = async () => {
  // console.log("Building...");
  // execSync("protostar build");
  console.log("Deploying ERC-721...");
  const erc721Command = await execProtostarCommand(
    'protostar -p devnet deploy ./build/pixel_erc721.json --inputs 1350069363 1347963987 20 0 "0x03BC4F3912468951B3Be911B9476177cc208DaE52Ae4f880540F4d24d3C61847" "0x00" "0x00" "0x00" "0x00"'
  );

  const erc721Address = erc721Command.match(contractRegex)[1];

  console.log("Deploying Drawer...");

  const drawerCommand = await execProtostarCommand(
    `protostar -p devnet deploy ./build/pixel_drawer.json --inputs "0x03BC4F3912468951B3Be911B9476177cc208DaE52Ae4f880540F4d24d3C61847" "${erc721Address}" 40`
  );
  const drawerAddress = drawerCommand.match(contractRegex)[1];

  console.log({ erc721Address, drawerAddress });
};

go();
