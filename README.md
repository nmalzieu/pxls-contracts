
  

# PXLS

Pxls is an on-chain collaborative commissioned art experiment. wtf??

Think of us as commissioning 3.0 - anyone can ask our 400-member community to draw an artwork representing the theme of his/her choice by participating in our rtwrk auctions. If you win the auction, we draw for you and you get the NFT of the artwork.

Learn more below or have fun visiting the [pxls website](https://pxls.wtf/).

## Contracts

There are 4 main contracts in Pxls:

- *PxlERC721* is the NFT contract for the 400 Pxls NFT. Each pxlr (= Pxls NFT holder) will be able to colorize the grid.
- *RtwrkDrawer* is the contract to draw rtwrks: it receives colorizations from pxlrs and saves them to the storage, then can reconstitute the grid
- *RtwrkThemeAuction* is our auction contract: there are 24 hours auctions during which bidders can bid on the theme of the next rtwrk! The winner’s theme is the theme of the next rtwrk the community will draw
- *RtwrkERC721* is the NFT contract for the rtwrks: each rtwrk is mintable as an NFT by the winner of the auction. The winner can even choose an intermediate “step” of the NFT as its image, meaning the rtwrks are actually dynamic NFTs containing all the steps of the process!

There are also 4 data contracts that contain the grids representing the visuals of the 400 Pxls NFTs (splitted in 4 contracts because of the contract size limit on Starknet).

A NFT grid representation is just an array of 400 felts, where each felt represents a predefined color. From these grids, the ERC-721 smart contracts generates the SVG and the JSON metadata using on-chain short string concatenation. Once the SVG is generated, it is inserted in the JSON as a `data:image/svg+xml` URI. Once the JSON metadata is generated, it is returned in the tokenURI contract method as a `data:application/json` URI.

All contracts have been made upgradeable through the proxy pattern to ensure a smooth transition during [Starknet regenesis](https://community.starknet.io/t/regenesis-state-migration-current-suggestion/2080).

### Build

First build all contracts

```
protostar build
```

### Data

Deploy the 4 pxl NFT data smart contracts:

```
protostar -p testnet deploy ./build/pxls_1_100.json

protostar -p testnet deploy ./build/pxls_101_200.json

protostar -p testnet deploy ./build/pxls_201_300.json

protostar -p testnet deploy ./build/pxls_301_400.json
```

and keep track of the address to which they are deployed.



## PXL ERC721 Contract

This contract is not using the Proxy pattern yet so its address will change an a migration (burn & mint) will happen.

```
protostar -p testnet deploy ./build/pxl_erc721.json --inputs 1350069363 1347963987 20 0 "<owner_account_address>" "<pxls_1_100_address>" "<pxls_101_200_address>" "<pxls_201_300_address>" "<pxls_301_400_address>"
```



### PXL NFT Collection Metadata

The `@view` method `contractURI` returns an IPFS link to a JSON file containing the collection metadata.

The hash is a list of short strings, it can be updated via the `setContractURIHash` method.

Current IPFS CID : `QmQvfChVRwfmzsjnHvm27R3c4UYqUod8fzzYrvLNuRhAHK`

## Drawer, Rtwrk ERC721, Auction contract

These contracts follow the Proxy pattern and are a bit more complicated to deploy. We propose a Protostar migration to deploy them:

```
protostar -p testnet migrate migrations/testnet/deploy_all_except_pxl_erc721.cairo
```

## RTWRK Drawer Contract

|  | Goerli | Mainnet |
| --- | --- | --- |
| RtwrkDrawer proxy address | 0xfad1d3c6c54aed8ea64a0c81231b5c2d1cae2aef347cbef9028648aeae0e2 | 0x0035345c560052c8d14dcbde85114c123fc3c65b7b5fab2d045fb3a7e57df453 |


## RTWRK Theme Auction Contract

|  | Goerli | Mainnet |
| --- | --- | --- |
| RtwrkThemeAuction proxy address | 0x7c3d5d4c41d50566f58ec8bd57cff5f0effd7c86e0ddd766283d99955cd6adc | 0x010649a7e51ebf2593eefcde93a525584701adb88ab078e09d08801d4763739a |

## RTWRK ERC 721 Contract

|  | Goerli | Mainnet |
| --- | --- | --- |
| RtwrkERC721 proxy address | 0x2e957ebc7e58b76b9bd17122f3bb452ce50fc810072fe298a156104a00061cc | 0x0044bac3f28118ea1946963a1bc1dc6e3752e2ed1b355c0113fd8087d2db6b66 |

### RTWRK NFT Collection Metadata

The `@view` method `contractURI` returns an IPFS link to a JSON file containing the collection metadata.

The hash is a list of short strings, it can be updated via the `setContractURIHash` method.

Current IPFS CID : `QmZ9rSfDK4LXFYxP9X2Ziw3jYcuSzrALAiAowFMfV6d9EZ`
