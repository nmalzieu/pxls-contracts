%lang starknet

@external
func up() {
    %{
        import json
        from starkware.starknet.public.abi import get_selector_from_name

        testnet_admin = 0x03bc4F3912468951b3be911b9476177CC208dAe52Ae4F880540F4d24d3c61847
        testnet_original_pixel_erc21_address = 0x07ffe4bd0b457e10674a2842164b91fea646ed4027d3b606a0fcbf056a4c8827

        pxls_1_100_address = pxl_erc721_proxy_address = deploy_contract("./build/pxls_1_100.json").contract_address
        pxls_101_200_address = pxl_erc721_proxy_address = deploy_contract("./build/pxls_101_200.json").contract_address
        pxls_201_300_address = pxl_erc721_proxy_address = deploy_contract("./build/pxls_201_300.json").contract_address
        pxls_301_400_address = pxl_erc721_proxy_address = deploy_contract("./build/pxls_301_400.json").contract_address

        # Let's deploy the Pxl ERC721 with proxy pattern
        pxl_erc721_hash = declare("./build/pxl_erc721.json", config={"wait_for_acceptance": True}).class_hash
        pxl_erc721_proxy_address = deploy_contract("./build/proxy.json", {
            "implementation_hash": pxl_erc721_hash,
            "selector": get_selector_from_name("initializer"),
            "calldata": [
                testnet_admin, # proxy_admin
                "Pxls", # name
                "PXLS", # symbol
                20, # m_size.low
                0, # m_size.high
                testnet_admin, # owner
                pxls_1_100_address, # pxls_1_100_address
                pxls_101_200_address, # pxls_101_200_address
                pxls_201_300_address, # pxls_201_300_address
                pxls_301_400_address,  # pxls_301_400_address
                testnet_original_pixel_erc21_address  # original_pixel_erc721_address
            ]
        }, config={"wait_for_acceptance": True}).contract_address

        print(json.dumps({
            "pxls_1_100_address": hex(pxls_1_100_address),
            "pxls_101_200_address": hex(pxls_101_200_address),
            "pxls_201_300_address": hex(pxls_201_300_address),
            "pxls_301_400_address": hex(pxls_301_400_address),
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
