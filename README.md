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
    
and keep track of the address to which they are deployed

## ERC721 Contract

    protostar -p testnet deploy ./build/pixel_erc721.json --inputs 1347963987 1347963987 "<owner_account_address>" 20 0 "<pxls_1_100_address>" "<pxls_101_200_address>" "<pxls_201_300_address>" "<pxls_301_400_address>"
