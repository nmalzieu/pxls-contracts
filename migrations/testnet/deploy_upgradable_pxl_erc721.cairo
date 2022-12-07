%lang starknet

@external
func up() {
    %{
        import json
        from starkware.starknet.public.abi import get_selector_from_name

        devnet_admin = 0x007d87450edc95e1753675ad0c944155cfa66a31e247f5b74ad5dba23331feb3
        devnet_eth_erc20 = 0x62230ea046a9a5fbc261ac77d03c8d41e5d442db2284587570ab46455fd2488
        pxls_1_100_address = 0x00
        pxls_101_200_address = 0x00
        pxls_201_300_address = 0x00
        pxls_301_400_address = 0x00

        # Let's deploy the Pxl ERC721 with proxy pattern
        pxl_erc721_hash = declare("./build/pxl_erc721.json").class_hash
        pxl_erc721_proxy_address = deploy_contract("./build/proxy.json", {
            "implementation_hash": pxl_erc721_hash,
            "selector": get_selector_from_name("initializer"),
            "calldata": [
                devnet_admin, # proxy_admin
                "Pxls", # name
                "PXLS", # symbol
                20, # m_size.low
                0, # m_size.high
                devnet_admin, # owner
                pxls_1_100_address, # pxls_1_100_address
                pxls_101_200_address, # pxls_101_200_address
                pxls_201_300_address, # pxls_201_300_address
                pxls_301_400_address,  # pxls_301_400_address
                0  # original_pixel_erc721_address
            ]
        }).contract_address

        print(json.dumps({
            "pxl_erc721_hash": hex(pxl_erc721_hash),
            "pxl_erc721_proxy_address": hex(pxl_erc721_proxy_address),
        }, indent=4))
    %}
    return ();
}

@external
func down() {
    %{ assert False, "Not implemented" %}
    return ();
}
