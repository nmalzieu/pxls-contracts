
# Deploying

  

## Build

  

First build all contracts

  

protostar build

  

## Data

  

Deploy the 4 pxl NFT data smart contracts:

    protostar -p testnet deploy ./build/pxls_1_100.json
    protostar -p testnet deploy ./build/pxls_101_200.json
    protostar -p testnet deploy ./build/pxls_201_300.json
    protostar -p testnet deploy ./build/pxls_301_400.json

and keep track of the address to which they are deployed.

  
On Goerli:

  
|Contract Name| Address |
|--|--|
|PXL Data 1-100| 0x05f9fa289cdb856b18abacc9809e3c465f129f5661d0933152c67d9fa7f9f0ed |
|PXL Data 101-200|0x039258f1153472e80444180c6c533aa29bd399e2c558f05f91ab725129614be0|
|PXL Data 201-300|0x030bbb244b56b6fcd5e2b8e5916790d8aef33b4ff477f25925ff63c1ea5339b0|
|PXL Data 301-400|0x042bc883299fbf767b31ba28babde517450dcedc761b865744264c9aaae480ae|


  
## ERC721 Contract

  
    protostar -p testnet deploy ./build/pixel_erc721.json --inputs 1350069363 1347963987 20 0 "<owner_account_address>" "<pxls_1_100_address>" "<pxls_101_200_address>" "<pxls_201_300_address>" "<pxls_301_400_address>"

  
  
On Goerli:

  
| Contract name | Address |
|--|--|
| PXL ERC721 Contract | 0x06113abe065dd65e33e8d979e1ec6cf7a3047296789119e8a2b5a0781a123dff |

### NFT Collection Metadata

The @view method `contractURI` returns an IPFS link to a JSON file containing the collection metadata.
The hash is a list of short strings, it can be updated via the `setContractURIHash` method.

Current IPFS CID : `QmbyCfLSj9yRwrtJ6EcpFKSxVXeiMzZb1qN3FSrY38qqQd`

## Drawer Contract

  
    protostar -p testnet deploy ./build/pixel_drawer.json --inputs "<pxl_erc721_contract_address>" "<owner_account_address>" "

  
  
On Goerli:

  
| Contract name | Address |
|--|--|
| PXL Drawer Contract | 0x0427ab643014d114629eda5e27976f71e4c504a6d75ad4ee290e443b17ba9f97 |

