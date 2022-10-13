%lang starknet

@external
func up() {
    %{
        import json
        from starkware.starknet.public.abi import get_selector_from_name

        devnet_admin = 0x03bc4F3912468951b3be911b9476177CC208dAe52Ae4F880540F4d24d3c61847
        rtwrk_erc721_proxy_address = 0x1583cfb81cbaae762bf61fde4eaa2de7ea5123b05cb6b3cab49fded18f22bca

        # Let's update the rtwrk ERC721 contract with proxy pattern
        new_rtwrk_erc721_hash = declare("./build/rtwrk_erc721.json", config={"wait_for_acceptance": True, "max_fee": "auto",}).class_hash
        invoke(
            rtwrk_erc721_proxy_address,
            "upgradeImplementation",
            {"new_implementation": new_rtwrk_erc721_hash},
            config={
                "auto_estimate_fee": True,
                "wait_for_acceptance": True,
            }
        )

        print({"new_rtwrk_erc721_hash": hex(new_rtwrk_erc721_hash)})
    %}
    return ();
}

@external
func down() {
    %{ assert False, "Not implemented" %}
    return ();
}
