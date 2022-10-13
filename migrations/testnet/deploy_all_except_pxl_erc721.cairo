%lang starknet

@external
func up() {
    %{
        import json
        from starkware.starknet.public.abi import get_selector_from_name

        testnet_admin = 0x03bc4F3912468951b3be911b9476177CC208dAe52Ae4F880540F4d24d3c61847
        testnet_eth_erc20 = 0x049d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7
        pxl_erc721_address = 0x07ffe4bd0b457e10674a2842164b91fea646ed4027d3b606a0fcbf056a4c8827
        auction_bid_increment = 100000000000 # On testnet, lower bid increment

        # Let's deploy the drawer contract with proxy pattern
        rtwrk_drawer_hash = declare("./build/rtwrk_drawer.json", config={"wait_for_acceptance": False, "max_fee": "auto",}).class_hash
        rtwrk_drawer_proxy_address = deploy_contract("./build/proxy.json", {
            "implementation_hash": rtwrk_drawer_hash,
            "selector": get_selector_from_name("initializer"),
            "calldata": [
                testnet_admin, # proxy_admin
                testnet_admin, # owner
                pxl_erc721_address, # pxl_erc721
            ]
        }, config={"wait_for_acceptance": False}).contract_address

        # Let's deploy the rtwrk ERC721 contract with proxy pattern
        rtwrk_erc721_hash = declare("./build/rtwrk_erc721.json", config={"wait_for_acceptance": False, "max_fee": "auto",}).class_hash
        rtwrk_erc721_proxy_address = deploy_contract("./build/proxy.json", {
            "implementation_hash": rtwrk_erc721_hash,
            "selector": get_selector_from_name("initializer"),
            "calldata": [
                testnet_admin, # proxy_admin
                testnet_admin, # owner
                rtwrk_drawer_proxy_address, # rtwrk_drawer_address_value
            ]
        }, config={"wait_for_acceptance": False}).contract_address

        # Let's deploy the rtwrk auction contract with proxy pattern
        rtwrk_theme_auction_hash = declare("./build/rtwrk_theme_auction.json", config={"wait_for_acceptance": False, "max_fee": "auto",}).class_hash
        rtwrk_theme_auction_proxy_address = deploy_contract("./build/proxy.json", {
            "implementation_hash": rtwrk_theme_auction_hash,
            "selector": get_selector_from_name("initializer"),
            "calldata": [
                testnet_admin, # proxy_admin
                testnet_admin, # owner
                testnet_eth_erc20, # eth_erc20_address_value
                pxl_erc721_address, #pxls_erc721_address_value
                rtwrk_drawer_proxy_address, # rtwrk_drawer_address_value
                rtwrk_erc721_proxy_address, # rtwrk_erc721_address_value
                auction_bid_increment # bid_increment_value
            ]
        }, config={"wait_for_acceptance": False}).contract_address

        # TO DO MANUALLY (can't use invoke here I don't know why)
        # call setRtwrkThemeAuctionContractAddress on
        # rtwrk_drawer_proxy_address and rtwrk_erc721_proxy_address

        print(json.dumps({
            "pxl_erc721_address": hex(pxl_erc721_address),
            "rtwrk_drawer_hash": hex(rtwrk_drawer_hash),
            "rtwrk_drawer_proxy_address": hex(rtwrk_drawer_proxy_address),
            "rtwrk_erc721_hash": hex(rtwrk_erc721_hash),
            "rtwrk_erc721_proxy_address": hex(rtwrk_erc721_proxy_address),
            "rtwrk_theme_auction_hash": hex(rtwrk_theme_auction_hash),
            "rtwrk_theme_auction_proxy_address": hex(rtwrk_theme_auction_proxy_address)
        }, indent=4))
    %}
    return ();
}

@external
func down() {
    %{ assert False, "Not implemented" %}
    return ();
}
