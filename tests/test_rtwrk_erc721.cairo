%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.bool import TRUE, FALSE

from pxls.RtwrkDrawer.original_rtwrks import ORIGINAL_RTWRKS_COUNT
from pxls.interfaces import IRtwrkERC721, IRtwrkDrawer

@view
func __setup__{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}() {
    %{
        from starkware.starknet.public.abi import get_selector_from_name
        context.account = 123456
    %}

    // Deploy an ETH ERC 20

    %{
        context.eth_erc_20_contract_address = deploy_contract("contracts/openzeppelin/token/erc20/presets/ERC20.cairo", {
               "name": "Ether",
               "symbol": "ETH",
               "decimals": 18,
               "initial_supply": 100000000000000000000,
               "recipient": 1212
           }).contract_address
    %}

    %{
        # Let's deploy the Pxl ERC721 with proxy pattern
        pxl_erc721_hash = declare("contracts/pxls/PxlERC721/PxlERC721.cairo").class_hash
        context.pxl_erc721_contract_address = deploy_contract("contracts/pxls/Proxy.cairo", {
            "implementation_hash": pxl_erc721_hash,
            "selector": get_selector_from_name("initializer"),
            "calldata": [
                context.account, # proxy_admin
                "Pxls", # name
                "PXLS", # symbol
                20, # m_size.low
                0, # m_size.high
                context.account, # owner
                0x00, # pxls_1_100_address
                0x00, # pxls_101_200_address
                0x00, # pxls_201_300_address
                0x00, # pxls_301_400_address
                0x00 # original_pixel_erc721_address
            ]
        }).contract_address
    %}

    // Deploy the drawer contract

    %{
        # Let's deploy the drawer contract with proxy pattern
        rtwrk_drawer_hash = declare("contracts/pxls/RtwrkDrawer/RtwrkDrawer.cairo").class_hash
        context.rtwrk_drawer_contract_address = deploy_contract("contracts/pxls/Proxy.cairo", {
            "implementation_hash": rtwrk_drawer_hash,
            "selector": get_selector_from_name("initializer"),
            "calldata": [
                context.account, # proxy_admin
                context.account, # owner
                context.pxl_erc721_contract_address, # pxl_erc721
            ]
        }).contract_address
    %}

    // Deploy the Rtwrk ERC721 contract

    %{
        rtwrk_erc721_hash = declare("contracts/pxls/RtwrkERC721/RtwrkERC721.cairo").class_hash
        context.rtwrk_erc721_contract_address = deploy_contract("contracts/pxls/Proxy.cairo", {
            "implementation_hash": rtwrk_erc721_hash,
            "selector": get_selector_from_name("initializer"),
            "calldata": [
                context.account, # proxy_admin
                context.account, # owner
                context.rtwrk_drawer_contract_address, # rtwrk_drawer_address_value
            ]
        }).contract_address
    %}

    // Deploy the auction contract

    %{
        rtwrk_theme_auction_hash = declare("contracts/pxls/RtwrkThemeAuction/RtwrkThemeAuction.cairo").class_hash
        context.auction_contract_address = deploy_contract("contracts/pxls/Proxy.cairo", {
            "implementation_hash": rtwrk_theme_auction_hash,
            "selector": get_selector_from_name("initializer"),
            "calldata": [
                context.account, # proxy_admin
                context.account, # owner
                context.eth_erc_20_contract_address, # eth_erc20_address_value
                context.pxl_erc721_contract_address, #pxls_erc721_address_value
                context.rtwrk_drawer_contract_address, # rtwrk_drawer_address_value
                context.rtwrk_erc721_contract_address, # rtwrk_erc721_address_value
                5000000000000000 # bid_increment_value
            ]
        }).contract_address
    %}

    // Set the auction contract address in the ERC721 contract

    tempvar rtwrk_erc721_contract_address;
    %{ ids.rtwrk_erc721_contract_address = context.rtwrk_erc721_contract_address %}

    tempvar auction_contract_address;
    %{ ids.auction_contract_address = context.auction_contract_address %}

    tempvar rtwrk_drawer_contract_address;
    %{ ids.rtwrk_drawer_contract_address = context.rtwrk_drawer_contract_address %}

    %{ stop_prank_rtwrk_erc721 = start_prank(context.account, target_contract_address=context.rtwrk_erc721_contract_address) %}

    IRtwrkERC721.setRtwrkThemeAuctionContractAddress(
        rtwrk_erc721_contract_address, auction_contract_address
    );

    %{ stop_prank_rtwrk_erc721 () %}

    %{ stop_prank_rtwrk_drawer = start_prank(context.account, target_contract_address=context.rtwrk_drawer_contract_address) %}

    IRtwrkDrawer.setRtwrkThemeAuctionContractAddress(
        rtwrk_drawer_contract_address, auction_contract_address
    );

    %{ stop_prank_rtwrk_drawer () %}

    return ();
}

@view
func test_rtwrk_erc721_getters{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}() {
    tempvar rtwrk_erc721_contract_address;
    %{ ids.rtwrk_erc721_contract_address = context.rtwrk_erc721_contract_address %}

    tempvar auction_contract_address;
    %{ ids.auction_contract_address = context.auction_contract_address %}

    let (exists) = IRtwrkERC721.exists(rtwrk_erc721_contract_address, Uint256(1, 0));
    assert TRUE = exists;

    // First NFTs are minted to the owner
    let (ownerOfToken) = IRtwrkERC721.ownerOf(rtwrk_erc721_contract_address, Uint256(11, 0));
    assert 123456 = ownerOfToken;

    let (auction_contract_address_in_rtwrk_erc721) = IRtwrkERC721.rtwrkThemeAuctionContractAddress(
        rtwrk_erc721_contract_address
    );
    assert auction_contract_address = auction_contract_address_in_rtwrk_erc721;

    return ();
}

@view
func test_rtwrk_erc721_token_uri_no_select_step{
    syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}() {
    alloc_locals;

    tempvar rtwrk_erc721_contract_address;
    %{ ids.rtwrk_erc721_contract_address = context.rtwrk_erc721_contract_address %}

    // Default step is 0 = last

    let (local token_uri_len, local token_uri: felt*) = IRtwrkERC721.tokenURI(
        rtwrk_erc721_contract_address, Uint256(11, 0)
    );

    assert '0\" fill=\"rgb(255,241,118' = token_uri[26];

    return ();
}

@view
func test_rtwrk_erc721_select_step{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}(
    ) {
    alloc_locals;

    tempvar rtwrk_erc721_contract_address;
    %{ ids.rtwrk_erc721_contract_address = context.rtwrk_erc721_contract_address %}

    %{ stop_prank_rtwrk_erc721 = start_prank(context.account, target_contract_address=context.rtwrk_erc721_contract_address) %}

    IRtwrkERC721.selectRtwrkStep(rtwrk_erc721_contract_address, Uint256(11, 0), 2);

    %{ stop_prank_rtwrk_erc721() %}

    let (local token_uri_len, local token_uri: felt*) = IRtwrkERC721.tokenURI(
        rtwrk_erc721_contract_address, Uint256(11, 0)
    );

    assert '0\" fill=\"rgb(150,150,150' = token_uri[26];

    %{ expect_revert(error_message="ERC721: caller is not the token owner") %}

    IRtwrkERC721.selectRtwrkStep(rtwrk_erc721_contract_address, Uint256(11, 0), 50);

    return ();
}
