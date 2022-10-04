%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.alloc import alloc

from pxls.interfaces import IPxlERC721

@view
func __setup__{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}() {
    let account = 123456;

    // Data contracts are heavy, deploying just a sample
    %{ context.sample_pxl_metadata_address = deploy_contract("tests/sample_pxl_metadata_contract.cairo", []).contract_address %}

    %{
        from starkware.starknet.public.abi import get_selector_from_name
        # Let's deploy the Pxl ERC721 with proxy pattern
        pxl_erc721_hash = declare("contracts/pxls/PxlERC721/PxlERC721.cairo").class_hash
        context.pxl_erc721_address = deploy_contract("contracts/pxls/Proxy.cairo", {
            "implementation_hash": pxl_erc721_hash,
            "selector": get_selector_from_name("initializer"),
            "calldata": [
                ids.account, # proxy_admin
                "Pxls", # name
                "PXLS", # symbol
                2, # m_size.low
                0, # m_size.high
                ids.account, # owner
                context.sample_pxl_metadata_address, # pxls_1_100_address
                context.sample_pxl_metadata_address, # pxls_101_200_address
                context.sample_pxl_metadata_address, # pxls_201_300_address
                context.sample_pxl_metadata_address  # pxls_301_400_address
            ]
        }).contract_address
    %}

    return ();
}

@view
func test_pxl_erc721_getters{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}() {
    tempvar pxl_erc721_address;
    %{ ids.pxl_erc721_address = context.pxl_erc721_address %}

    let (matrix_size: Uint256) = IPxlERC721.matrixSize(contract_address=pxl_erc721_address);
    assert matrix_size.low = 2;
    assert matrix_size.high = 0;

    let (max_supply: Uint256) = IPxlERC721.maxSupply(contract_address=pxl_erc721_address);
    assert max_supply.low = 4;
    assert max_supply.high = 0;

    let (owner: felt) = IPxlERC721.owner(contract_address=pxl_erc721_address);
    assert 123456 = owner;

    // Check that minted pixels count is 0

    let (total_supply: Uint256) = IPxlERC721.totalSupply(contract_address=pxl_erc721_address);
    assert total_supply.low = 0;
    assert total_supply.high = 0;

    return ();
}

@view
func test_pxl_erc721_transfer_ownership{
    syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}() {
    tempvar pxl_erc721_address;
    %{ ids.pxl_erc721_address = context.pxl_erc721_address %}
    let (owner: felt) = IPxlERC721.owner(contract_address=pxl_erc721_address);
    assert 123456 = owner;

    %{ stop_prank = start_prank(123456, target_contract_address=ids.pxl_erc721_address) %}
    IPxlERC721.transferOwnership(pxl_erc721_address, 123457);
    %{ stop_prank() %}

    let (owner: felt) = IPxlERC721.owner(contract_address=pxl_erc721_address);
    assert 123457 = owner;

    %{ expect_revert(error_message="Ownable: caller is not the owner") %}
    IPxlERC721.transferOwnership(pxl_erc721_address, 123457);

    return ();
}

@view
func test_pxl_erc721_contract_uri{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}(
    ) {
    alloc_locals;

    local pxl_erc721_address;
    %{ ids.pxl_erc721_address = context.pxl_erc721_address %}

    let (contract_uri_len: felt, contract_uri: felt*) = IPxlERC721.contractURI(
        contract_address=pxl_erc721_address
    );
    assert 4 = contract_uri_len;
    assert 'ipfs://' = contract_uri[0];
    assert 0 = contract_uri[1];
    assert 0 = contract_uri[2];
    assert 0 = contract_uri[3];

    %{ stop_prank = start_prank(123456, target_contract_address=ids.pxl_erc721_address) %}
    let (hash: felt*) = alloc();
    assert hash[0] = 'vez2qw8z6poiozzgjqnbapzcekb4h8j';
    assert hash[1] = 'hsiuxvjaqqb4e6p0synfwnxobnes6m7';
    assert hash[2] = 'j66w';
    IPxlERC721.setContractURIHash(contract_address=pxl_erc721_address, hash_len=3, hash=hash);
    let (contract_uri_len: felt, contract_uri: felt*) = IPxlERC721.contractURI(
        contract_address=pxl_erc721_address
    );
    assert 4 = contract_uri_len;
    assert 'ipfs://' = contract_uri[0];
    assert 'vez2qw8z6poiozzgjqnbapzcekb4h8j' = contract_uri[1];
    assert 'hsiuxvjaqqb4e6p0synfwnxobnes6m7' = contract_uri[2];
    assert 'j66w' = contract_uri[3];

    %{ stop_prank() %}

    // Verify that only owner can set contract uri hash
    %{ expect_revert(error_message="Ownable: caller is not the owner") %}
    IPxlERC721.setContractURIHash(contract_address=pxl_erc721_address, hash_len=3, hash=hash);

    return ();
}

@view
func test_pxl_erc721_mint{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}() {
    tempvar pxl_erc721_address;
    %{ ids.pxl_erc721_address = context.pxl_erc721_address %}

    %{ stop_prank = start_prank(123456, target_contract_address=ids.pxl_erc721_address) %}

    IPxlERC721.mint(contract_address=pxl_erc721_address, to=123456);

    // Check that minted pixels count is 1

    let (total_supply: Uint256) = IPxlERC721.totalSupply(contract_address=pxl_erc721_address);
    assert total_supply.low = 1;
    assert total_supply.high = 0;

    // Check that can't mint a second one

    %{ expect_revert(error_message="123456 already owns a pxl") %}

    IPxlERC721.mint(contract_address=pxl_erc721_address, to=123456);

    %{ stop_prank() %}
    return ();
}

@view
func test_pxl_erc721_max_supply{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}() {
    tempvar pxl_erc721_address;
    %{ ids.pxl_erc721_address = context.pxl_erc721_address %}

    %{ stop_prank = start_prank(123456, target_contract_address=ids.pxl_erc721_address) %}

    // Let's mint 4 so we get to max supply

    IPxlERC721.mint(contract_address=pxl_erc721_address, to=123456);
    IPxlERC721.mint(contract_address=pxl_erc721_address, to=123457);
    IPxlERC721.mint(contract_address=pxl_erc721_address, to=123458);
    IPxlERC721.mint(contract_address=pxl_erc721_address, to=123459);

    // Check that minted pixels count is 4

    let (total_supply: Uint256) = IPxlERC721.totalSupply(contract_address=pxl_erc721_address);
    assert total_supply.low = 4;
    assert total_supply.high = 0;

    // Check that once max supply is reached we can't mint anymore
    %{ expect_revert(error_message="Total pxl supply has already been minted") %}
    IPxlERC721.mint(contract_address=pxl_erc721_address, to=123460);

    %{ stop_prank() %}
    return ();
}

@view
func test_pxl_erc721_pixels_of_owner{
    syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}() {
    tempvar pxl_erc721_address;
    %{ ids.pxl_erc721_address = context.pxl_erc721_address %}

    // Let's mint 3 to 3  different addresses

    IPxlERC721.mint(contract_address=pxl_erc721_address, to=123456);
    IPxlERC721.mint(contract_address=pxl_erc721_address, to=123457);
    IPxlERC721.mint(contract_address=pxl_erc721_address, to=123458);

    // Let's check that first address has 1

    let (owned_pxls_123456_len, owned_pxls_123456: felt*) = IPxlERC721.pxlsOwned(
        pxl_erc721_address, 123456
    );
    assert 1 = owned_pxls_123456_len;

    // Let's transfer from 123456 to 123458

    %{ stop_prank = start_prank(123456, target_contract_address=ids.pxl_erc721_address) %}

    IPxlERC721.transferFrom(pxl_erc721_address, 123456, 123458, Uint256(owned_pxls_123456[0], 0));

    %{ stop_prank() %}

    // Let's check transfer worked

    let (owned_pxls_123456_len, owned_pixels_123456: felt*) = IPxlERC721.pxlsOwned(
        pxl_erc721_address, 123456
    );
    assert 0 = owned_pxls_123456_len;

    let (owned_pxls_123458_len, owned_pxls_123458: felt*) = IPxlERC721.pxlsOwned(
        pxl_erc721_address, 123458
    );
    assert 2 = owned_pxls_123458_len;

    // 123458 first minted the 3rd pixel
    assert 3 = owned_pxls_123458[0];
    // then got the 1st pixel transfered
    assert 1 = owned_pxls_123458[1];

    return ();
}

@view
func test_pxl_erc721_token_uri{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}() {
    tempvar pxl_erc721_address;
    %{ ids.pxl_erc721_address = context.pxl_erc721_address %}

    let token_id: Uint256 = Uint256(1, 0);
    let (token_uri_len: felt, token_uri: felt*) = IPxlERC721.tokenURI(
        contract_address=pxl_erc721_address, tokenId=token_id
    );

    assert 1631 = token_uri_len;
    assert 'data:application/json;' = token_uri[0];
    assert 'cyan' = token_uri[5];  // Second felt of cyan attribute
    // Third felt of blue attribute: blue palette is
    // present and it's not the last palette so end with ,
    assert '","value":"yes"},' = token_uri[9];

    // Check that we can also reach other data smart contracts
    let token_id: Uint256 = Uint256(101, 0);
    let (token_uri_len: felt, token_uri: felt*) = IPxlERC721.tokenURI(
        contract_address=pxl_erc721_address, tokenId=token_id
    );

    assert 1631 = token_uri_len;

    let token_id: Uint256 = Uint256(201, 0);
    let (token_uri_len: felt, token_uri: felt*) = IPxlERC721.tokenURI(
        contract_address=pxl_erc721_address, tokenId=token_id
    );

    assert 1631 = token_uri_len;

    let token_id: Uint256 = Uint256(301, 0);
    let (token_uri_len: felt, token_uri: felt*) = IPxlERC721.tokenURI(
        contract_address=pxl_erc721_address, tokenId=token_id
    );

    assert 1631 = token_uri_len;

    return ();
}
