%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256

from pxls.interfaces import IPxlERC721, IOriginalPixelERC721

@view
func __setup__{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}() {
    // Deploy a sample ERC-721 contract
    %{
        context.account = 123456
        context.original_erc_721_address = deploy_contract("contracts/openzeppelin/token/erc721/enumerable/presets/ERC721EnumerableMintableBurnable.cairo", [1350069363, 1347963987, context.account]).contract_address
    %}

    %{
        from starkware.starknet.public.abi import get_selector_from_name
        # Let's deploy the Pxl ERC721 with proxy pattern
        pxl_erc721_hash = declare("contracts/pxls/PxlERC721/PxlERC721.cairo").class_hash
        context.pxl_erc721_address = deploy_contract("contracts/pxls/Proxy.cairo", {
            "implementation_hash": pxl_erc721_hash,
            "selector": get_selector_from_name("initializer"),
            "calldata": [
                context.account, # proxy_admin
                "Pxls", # name
                "PXLS", # symbol
                2, # m_size.low
                0, # m_size.high
                context.account, # owner
                0, # pxls_1_100_address
                0, # pxls_101_200_address
                0, # pxls_201_300_address
                0, # pxls_301_400_address
                context.original_erc_721_address # original_pixel_erc721_address
            ]
        }).contract_address
    %}

    return ();
}

@view
func test_cant_mint{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}() {
    tempvar pxl_erc721_address;

    %{ ids.pxl_erc721_address = context.pxl_erc721_address %}

    %{ expect_revert(error_message="This method cannot be called if original_pixel_erc721 is se") %}

    IPxlERC721.mint(contract_address=pxl_erc721_address, to=121212);

    return ();
}

@view
func test_burn_and_mint_nonexistent_pxl{
    syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}() {
    tempvar pxl_erc721_address;

    %{ ids.pxl_erc721_address = context.pxl_erc721_address %}

    %{ expect_revert(error_message="ERC721: owner query for nonexistent token") %}

    IPxlERC721.burnAndMint(contract_address=pxl_erc721_address, tokenId=Uint256(1, 0));

    return ();
}

@view
func test_burn_and_mint_nonowner_pxl{
    syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}() {
    tempvar original_erc_721_address;
    tempvar pxl_erc721_address;
    tempvar account;

    %{
        ids.account = context.account
        ids.original_erc_721_address = context.original_erc_721_address
        ids.pxl_erc721_address = context.pxl_erc721_address
    %}

    // Let's first mint to 121212
    %{ stop_prank = start_prank(context.account, target_contract_address=context.original_erc_721_address) %}
    IOriginalPixelERC721.mint(
        contract_address=original_erc_721_address, to=121212, tokenId=Uint256(247, 0)
    );
    %{ stop_prank() %}

    // Let's try to burn as not 121212
    %{ expect_revert(error_message="You don't own this original PXL NFT") %}
    IPxlERC721.burnAndMint(contract_address=pxl_erc721_address, tokenId=Uint256(247, 0));

    return ();
}

@view
func test_burn_and_mint_nonapproved_pxl{
    syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}() {
    tempvar original_erc_721_address;
    tempvar pxl_erc721_address;
    tempvar account;

    %{
        ids.account = context.account
        ids.original_erc_721_address = context.original_erc_721_address
        ids.pxl_erc721_address = context.pxl_erc721_address
    %}

    // Let's first mint to 121212
    %{ stop_prank_old_erc721 = start_prank(context.account, target_contract_address=context.original_erc_721_address) %}
    IOriginalPixelERC721.mint(
        contract_address=original_erc_721_address, to=121212, tokenId=Uint256(247, 0)
    );
    %{ stop_prank_old_erc721() %}

    // Let's try to burn as 121212
    %{ stop_prank_pxl_erc721 = start_prank(121212, target_contract_address=context.pxl_erc721_address) %}
    %{ expect_revert(error_message="ERC721: either is not approved or the caller is the zero address") %}
    IPxlERC721.burnAndMint(contract_address=pxl_erc721_address, tokenId=Uint256(247, 0));
    %{ stop_prank_pxl_erc721() %}

    return ();
}

@view
func test_burn_and_mint_approved_pxl{
    syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}() {
    tempvar original_erc_721_address;
    tempvar pxl_erc721_address;
    tempvar account;

    %{
        ids.account = context.account
        ids.original_erc_721_address = context.original_erc_721_address
        ids.pxl_erc721_address = context.pxl_erc721_address
    %}

    // Original totalSupply of the new contract is 0
    let (supply) = IPxlERC721.totalSupply(contract_address=pxl_erc721_address);
    assert 0 = supply.low;
    assert 0 = supply.high;

    // Let's first mint to 121212
    %{ stop_prank_old_erc721 = start_prank(context.account, target_contract_address=context.original_erc_721_address) %}
    IOriginalPixelERC721.mint(
        contract_address=original_erc_721_address, to=121212, tokenId=Uint256(247, 0)
    );
    %{ stop_prank_old_erc721() %}

    // 121212 is now owner
    let (owner_of_original_pxl) = IOriginalPixelERC721.ownerOf(
        contract_address=original_erc_721_address, tokenId=Uint256(247, 0)
    );
    assert 121212 = owner_of_original_pxl;

    // Let's try to burn as 121212
    %{ stop_prank_pxl_erc721 = start_prank(121212, target_contract_address=context.pxl_erc721_address) %}
    %{ stop_prank_old_erc721 = start_prank(121212, target_contract_address=context.original_erc_721_address) %}
    IOriginalPixelERC721.approve(
        contract_address=original_erc_721_address, to=pxl_erc721_address, tokenId=Uint256(247, 0)
    );
    IPxlERC721.burnAndMint(contract_address=pxl_erc721_address, tokenId=Uint256(247, 0));
    %{ stop_prank_old_erc721() %}
    %{ stop_prank_pxl_erc721() %}

    // Dead address is now owner of original pixel
    let (owner_of_original_pxl) = IOriginalPixelERC721.ownerOf(
        contract_address=original_erc_721_address, tokenId=Uint256(247, 0)
    );
    assert 0x000000000000000000000000000000000000dEaD = owner_of_original_pxl;
    // Total supply of new pixel has increased
    let (supply) = IPxlERC721.totalSupply(contract_address=pxl_erc721_address);
    assert 1 = supply.low;
    assert 0 = supply.high;

    // 121212 address is now owner of new pixel
    let (owner_of_new_pxl) = IPxlERC721.ownerOf(
        contract_address=pxl_erc721_address, tokenId=Uint256(247, 0)
    );
    assert 121212 = owner_of_new_pxl;
    return ();
}
