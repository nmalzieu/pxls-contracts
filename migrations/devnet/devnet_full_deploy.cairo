%lang starknet

@external
func up() {
    %{
        import json
        from starkware.starknet.public.abi import get_selector_from_name

        devnet_admin = 0x04309BC130903CA23a0C540B1d9fe6453dAfC031a587704d0573C11EA4388714
        devnet_eth_erc20 = 0x62230ea046a9a5fbc261ac77d03c8d41e5d442db2284587570ab46455fd2488
        auction_bid_increment = 1000000000000000

        # Let's deploy the Pxl ERC721 with proxy pattern
        pxl_erc721_hash = declare("./build/pxl_erc721.json", config={"wait_for_acceptance": True, "max_fee": "auto",}).class_hash
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
                0x00, # pxls_1_100_address
                0x00, # pxls_101_200_address
                0x00, # pxls_201_300_address
                0x00, # pxls_301_400_address
                0x00  # old_pxls_address
            ]
        }, config={"wait_for_acceptance": True}).contract_address

        # Let's deploy the drawer contract with proxy pattern
        rtwrk_drawer_hash = declare("./build/rtwrk_drawer.json", config={"wait_for_acceptance": True, "max_fee": "auto",}).class_hash
        rtwrk_drawer_proxy_address = deploy_contract("./build/proxy.json", {
            "implementation_hash": rtwrk_drawer_hash,
            "selector": get_selector_from_name("initializer"),
            "calldata": [
                devnet_admin, # proxy_admin
                devnet_admin, # owner
                pxl_erc721_proxy_address, # pxl_erc721
            ]
        }, config={"wait_for_acceptance": True}).contract_address

        # Let's deploy the rtwrk ERC721 contract with proxy pattern
        rtwrk_erc721_hash = declare("./build/rtwrk_erc721.json", config={"wait_for_acceptance": True, "max_fee": "auto",}).class_hash
        rtwrk_erc721_proxy_address = deploy_contract("./build/proxy.json", {
            "implementation_hash": rtwrk_erc721_hash,
            "selector": get_selector_from_name("initializer"),
            "calldata": [
                devnet_admin, # proxy_admin
                devnet_admin, # owner
                rtwrk_drawer_proxy_address, # rtwrk_drawer_address_value
            ]
        }, config={"wait_for_acceptance": True}).contract_address

        # Let's deploy the rtwrk auction contract with proxy pattern
        rtwrk_theme_auction_hash = declare("./build/rtwrk_theme_auction.json", config={"wait_for_acceptance": True, "max_fee": "auto",}).class_hash
        rtwrk_theme_auction_proxy_address = deploy_contract("./build/proxy.json", {
            "implementation_hash": rtwrk_theme_auction_hash,
            "selector": get_selector_from_name("initializer"),
            "calldata": [
                devnet_admin, # proxy_admin
                devnet_admin, # owner
                devnet_eth_erc20, # eth_erc20_address_value
                pxl_erc721_proxy_address, #pxls_erc721_address_value
                rtwrk_drawer_proxy_address, # rtwrk_drawer_address_value
                rtwrk_erc721_proxy_address, # rtwrk_erc721_address_value
                auction_bid_increment, # bid_increment_value
            ]
        }, config={"wait_for_acceptance": True}).contract_address

        invoke(
            rtwrk_drawer_proxy_address,
            "setRtwrkThemeAuctionContractAddress",
            {"address": rtwrk_theme_auction_proxy_address},
            config={
                "wait_for_acceptance": True,
                "max_fee": "auto",
            }
        )

        invoke(
            rtwrk_erc721_proxy_address,
            "setRtwrkThemeAuctionContractAddress",
            {"address": rtwrk_theme_auction_proxy_address},
            config={
                "wait_for_acceptance": True,
                "max_fee": "auto",
            }
        )

        print(json.dumps({
            "pxl_erc721_hash": hex(pxl_erc721_hash),
            "pxl_erc721_proxy_address": hex(pxl_erc721_proxy_address),
            "rtwrk_drawer_hash": hex(rtwrk_drawer_hash),
            "rtwrk_drawer_proxy_address": hex(rtwrk_drawer_proxy_address),
            "rtwrk_erc721_hash": hex(rtwrk_erc721_hash),
            "rtwrk_erc721_proxy_address": hex(rtwrk_erc721_proxy_address),
            "rtwrk_theme_auction_hash": hex(rtwrk_theme_auction_hash),
            "rtwrk_theme_auction_proxy_address": hex(rtwrk_theme_auction_proxy_address)
        }, indent=4))

        # Let's try to invoke
    %}
    return ();
}

@external
func down() {
    %{ assert False, "Not implemented" %}
    return ();
}
