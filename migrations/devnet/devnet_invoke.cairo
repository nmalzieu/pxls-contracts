%lang starknet

@external
func up() {
    %{
        import json
        from starkware.starknet.public.abi import get_selector_from_name

        devnet_admin = 0x03bc4F3912468951b3be911b9476177CC208dAe52Ae4F880540F4d24d3c61847
        pxl_erc721_proxy_address = 0x2e3f4ab428a5103244d6d6488c48951b73e00acec875fcbea3cb6ffe0810282
        rtwrk_drawer_proxy_address = 0x1987cb0622b9e49ad4d093cf2c96a2a1bb6da58962c96b2a1bd1d42572da3f5
        rtwrk_erc721_proxy_address = 0x26702f58855662af84d1deb9c7ac2799fa0d9fe6fb341adf2027c807fdf0ab9
        rtwrk_theme_auction_proxy_address = 0x87ebca79ec5c0cfeeaebcb0012ad05ccf2f9bcb37bb37447654f3def10b026

        # Let's try to invoke
        invoke(
            rtwrk_drawer_proxy_address,
            "setRtwrkThemeAuctionContractAddress",
            [rtwrk_theme_auction_proxy_address],
            config={
                "auto_estimate_fee": True,
                "wait_for_acceptance": True,
            }
        )
        invoke(
            rtwrk_erc721_proxy_address,
            "setRtwrkThemeAuctionContractAddress",
            [rtwrk_theme_auction_proxy_address],
            config={
                "auto_estimate_fee": True,
                "wait_for_acceptance": True,
            }
        )
        

    %}
    return ();
}

@external
func down() {
    %{ assert False, "Not implemented" %}
    return ();
}
