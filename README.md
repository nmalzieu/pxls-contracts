
# PXLS

Pxls is an experimental attempt to create on-chain collaborative artworks (”rtwrks”).

Every day, our 400-member community creates a new artwork by colorizing a 20*20 pixels grid. Our goal is to create interesting artworks, of course, but also to explore how a group of people gets common inspiration, creates and learns together.

Learn more below or have a look at our artworks on the [pxls website](https://pxls.wtf/).

## Contracts

There are two main contracts right now:
- PixelERC72 is the NFT contract for the 400 Pxls NFT. Each Pxls NFT holder will be able to colorize a pixel of the daily rtwrk.
- PixelDrawer is the Drawer contract: everyday each Pxls NFT will have a new "position" in a 20x20 grid and the holder will be able to colorize this pixel.

There are also 4 data contracts that contain the grids representing the visuals of the 400 Pxls NFTs (splitted in 4 contracts because of the contract size limit on Starknet).
A Pxls NFT grid representation is just an array of 400 felts, where each felt represents a predefined color. From these grids, the ERC-721 smart contracts generates the SVG and the JSON metadata using on-chain short string concatenation. Once the SVG is generated, it is inserted in the JSON as a `data:image/svg+xml` URI. Once the JSON metadata is generated, it is returned in the tokenURI contract method as a `data:application/json` URI.


### Build


First build all contracts

    protostar build


### Data


Deploy the 4 pxl NFT data smart contracts:

    protostar -p testnet deploy ./build/pxls_1_100.json
    protostar -p testnet deploy ./build/pxls_101_200.json
    protostar -p testnet deploy ./build/pxls_201_300.json
    protostar -p testnet deploy ./build/pxls_301_400.json

and keep track of the address to which they are deployed.


  
|Contract Name| Goerli Address | Mainnet Address |
|--|--|--|
|PXL Data 1-100|[0x069043693319d1c842af8ebfa9581e761d5031201a621dc9c58b6b9c4607f07b](https://goerli.voyager.online/contract/0x069043693319d1c842af8ebfa9581e761d5031201a621dc9c58b6b9c4607f07b) |[0x0428f9440b24d3e46def5f307099188ef0ed660240c15381b172d56d223866ba](https://voyager.online/contract/0x0428f9440b24d3e46def5f307099188ef0ed660240c15381b172d56d223866ba) |
|PXL Data 101-200|[0x02598cb1b074fc3551fcbbd45f3c7570ed89a353fd0828772176bd68072021b0](https://goerli.voyager.online/contract/0x02598cb1b074fc3551fcbbd45f3c7570ed89a353fd0828772176bd68072021b0)|[0x067bf3e6fc1539ca25816871ce4bc8f15ce118374c8a8f789e5132c0ce616ab4](https://voyager.online/contract/0x067bf3e6fc1539ca25816871ce4bc8f15ce118374c8a8f789e5132c0ce616ab4)|
|PXL Data 201-300|[0x0167668d850ddec4ed552b0967438872d5ecf96c901166267c49201a4a72505f](https://goerli.voyager.online/contract/0x0167668d850ddec4ed552b0967438872d5ecf96c901166267c49201a4a72505f)|[0x01d217766a832af9bd6a1e3d53f5c2c6636a56a2848a2d6832d44d6ee41628bf](https://voyager.online/contract/0x01d217766a832af9bd6a1e3d53f5c2c6636a56a2848a2d6832d44d6ee41628bf)|
|PXL Data 301-400|[0x04b01968df90ddca33565f1f54c0d0b3b456628eba3b4b0455ea18f90f95d702](https://goerli.voyager.online/contract/0x04b01968df90ddca33565f1f54c0d0b3b456628eba3b4b0455ea18f90f95d702)|[0x04d8698d6a7f2d3906bc89ac50892cf33cab06d7f3ad5f4d0e06a71ba7bc3f14](https://voyager.online/contract/0x04d8698d6a7f2d3906bc89ac50892cf33cab06d7f3ad5f4d0e06a71ba7bc3f14)|

  
## ERC721 Contract

  
    protostar -p testnet deploy ./build/pixel_erc721.json --inputs 1350069363 1347963987 20 0 "<owner_account_address>" "<pxls_1_100_address>" "<pxls_101_200_address>" "<pxls_201_300_address>" "<pxls_301_400_address>"


  
| Contract name | Goerli Address | Mainnet Address |
|--|--|--|
| PXL ERC721 Contract | [0x07ffe4bd0b457e10674a2842164b91fea646ed4027d3b606a0fcbf056a4c8827](https://goerli.voyager.online/contract/0x07ffe4bd0b457e10674a2842164b91fea646ed4027d3b606a0fcbf056a4c8827) | [0x045963ea13d95f22b58a5f0662ed172278e6b420cded736f846ca9bde8ea476a](https://voyager.online/contract/0x045963ea13d95f22b58a5f0662ed172278e6b420cded736f846ca9bde8ea476a) |

### NFT Collection Metadata

The `@view` method `contractURI` returns an IPFS link to a JSON file containing the collection metadata.
The hash is a list of short strings, it can be updated via the `setContractURIHash` method.

Current IPFS CID : `QmQvfChVRwfmzsjnHvm27R3c4UYqUod8fzzYrvLNuRhAHK`

## Drawer Contract

  
    protostar -p testnet deploy ./build/pixel_drawer.json --inputs "<owner_account_address>" "<pxl_erc721_contract_address>" <max_colorizations_per_token>



| Contract name | Goerli Address | Mainnet Address |
|--|--|--|
| PXL Drawer Contract | [0x01e6ed1dc5b447087f7363a771cd2718f4ca71b701cc62ef68766768095b47a7](https://goerli.voyager.online/contract/0x01e6ed1dc5b447087f7363a771cd2718f4ca71b701cc62ef68766768095b47a7) | [0x01ecc7d613273e6190444ce95ee1459645127104f78b669f04062d8f93d398e8](https://voyager.online/contract/0x01ecc7d613273e6190444ce95ee1459645127104f78b669f04062d8f93d398e8) |
