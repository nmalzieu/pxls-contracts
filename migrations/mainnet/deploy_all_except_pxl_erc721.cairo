%lang starknet

@external
func up() {
    %{
        import json
        from starkware.starknet.public.abi import get_selector_from_name

        mainnet_admin = 0x01028cB54B6A7DCf8D12bfE8aA0DFBe7A98D9c34BfacC71220193b62610F7623
        mainnet_eth_erc20 = 0x049d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7
        pxl_erc721_address = 0x045963ea13d95f22b58a5f0662ed172278e6b420cded736f846ca9bde8ea476a
        auction_bid_increment = 10000000000000000 # On mainnet, bid increment is 0.01 ETH

        # Let's deploy the drawer contract with proxy pattern
        rtwrk_drawer_hash = declare("./build/rtwrk_drawer.json", config={"wait_for_acceptance": False, "max_fee": "auto",}).class_hash
        rtwrk_drawer_proxy_address = deploy_contract("./build/proxy.json", {
            "implementation_hash": rtwrk_drawer_hash,
            "selector": get_selector_from_name("initializer"),
            "calldata": [
                mainnet_admin, # proxy_admin
                mainnet_admin, # owner
                pxl_erc721_address, # pxl_erc721
            ]
        }, config={"wait_for_acceptance": False}).contract_address

        # Let's deploy the rtwrk ERC721 contract with proxy pattern
        rtwrk_erc721_hash = declare("./build/rtwrk_erc721.json", config={"wait_for_acceptance": False, "max_fee": "auto",}).class_hash
        rtwrk_erc721_proxy_address = deploy_contract("./build/proxy.json", {
            "implementation_hash": rtwrk_erc721_hash,
            "selector": get_selector_from_name("initializer"),
            "calldata": [
                mainnet_admin, # proxy_admin
                mainnet_admin, # owner
                rtwrk_drawer_proxy_address, # rtwrk_drawer_address_value
            ]
        }, config={"wait_for_acceptance": False}).contract_address

        # Let's deploy the rtwrk auction contract with proxy pattern
        rtwrk_theme_auction_hash = declare("./build/rtwrk_theme_auction.json", config={"wait_for_acceptance": False, "max_fee": "auto",}).class_hash
        rtwrk_theme_auction_proxy_address = deploy_contract("./build/proxy.json", {
            "implementation_hash": rtwrk_theme_auction_hash,
            "selector": get_selector_from_name("initializer"),
            "calldata": [
                mainnet_admin, # proxy_admin
                mainnet_admin, # owner
                mainnet_eth_erc20, # eth_erc20_address_value
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
