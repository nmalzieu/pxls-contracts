%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256
from starkware.starknet.common.syscalls import get_caller_address
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.math import assert_le, assert_not_zero

from openzeppelin.access.ownable.library import Ownable
from openzeppelin.token.erc721.library import ERC721
from openzeppelin.token.erc721.enumerable.library import ERC721Enumerable
from openzeppelin.introspection.erc165.library import ERC165
from openzeppelin.upgrades.library import Proxy

from pxls.RtwrkERC721.storage import (
    contract_uri_hash,
    rtwrk_drawer_address,
    rtwrk_theme_auction_address,
    rtwrk_chosen_step,
)
from pxls.RtwrkERC721.drawer import rtwrk_steps_count, rtwrk_token_uri

//
// Initializer
//

@external
func initializer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    proxy_admin: felt, owner: felt, rtwrk_drawer_address_value: felt
) {
    Proxy.initializer(proxy_admin);
    ERC721.initializer('Pxls Rtwrks', 'RTWRKS');
    ERC721Enumerable.initializer();
    Ownable.initializer(owner);
    rtwrk_drawer_address.write(rtwrk_drawer_address_value);

    // Minting all rtwrks prior to deployment to the owner

    ERC721Enumerable._mint(owner, Uint256(1, 0));
    ERC721Enumerable._mint(owner, Uint256(2, 0));
    ERC721Enumerable._mint(owner, Uint256(3, 0));
    ERC721Enumerable._mint(owner, Uint256(4, 0));
    ERC721Enumerable._mint(owner, Uint256(5, 0));
    ERC721Enumerable._mint(owner, Uint256(6, 0));
    ERC721Enumerable._mint(owner, Uint256(7, 0));
    ERC721Enumerable._mint(owner, Uint256(8, 0));
    ERC721Enumerable._mint(owner, Uint256(9, 0));
    ERC721Enumerable._mint(owner, Uint256(10, 0));
    ERC721Enumerable._mint(owner, Uint256(11, 0));

    return ();
}

//
// Getters
//

@view
func supportsInterface{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    interfaceId: felt
) -> (success: felt) {
    let (success) = ERC165.supports_interface(interfaceId);
    return (success,);
}

@view
func name{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (name: felt) {
    let (name) = ERC721.name();
    return (name,);
}

@view
func symbol{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (symbol: felt) {
    let (symbol) = ERC721.symbol();
    return (symbol,);
}

@view
func balanceOf{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(owner: felt) -> (
    balance: Uint256
) {
    let (balance: Uint256) = ERC721.balance_of(owner);
    return (balance,);
}

@view
func ownerOf{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(tokenId: Uint256) -> (
    owner: felt
) {
    let (owner: felt) = ERC721.owner_of(tokenId);
    return (owner,);
}

@view
func exists{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(tokenId: Uint256) -> (
    token_exists: felt
) {
    let token_exists = ERC721._exists(tokenId);
    return (token_exists,);
}

@view
func getApproved{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    tokenId: Uint256
) -> (approved: felt) {
    let (approved: felt) = ERC721.get_approved(tokenId);
    return (approved,);
}

@view
func isApprovedForAll{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    owner: felt, operator: felt
) -> (isApproved: felt) {
    let (isApproved: felt) = ERC721.is_approved_for_all(owner, operator);
    return (isApproved,);
}

@view
func contractURI{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    contractURI_len: felt, contractURI: felt*
) {
    // Max length of CID can be stored in 3 short strings
    let (ipfs_hash_0) = contract_uri_hash.read(0);
    let (ipfs_hash_1) = contract_uri_hash.read(1);
    let (ipfs_hash_2) = contract_uri_hash.read(2);
    let (contract_uri: felt*) = alloc();
    assert contract_uri[0] = 'ipfs://';
    assert contract_uri[1] = ipfs_hash_0;
    assert contract_uri[2] = ipfs_hash_1;
    assert contract_uri[3] = ipfs_hash_2;
    return (contractURI_len=4, contractURI=contract_uri);
}

@view
func tokenURI{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    tokenId: Uint256
) -> (tokenURI_len: felt, tokenURI: felt*) {
    let (tokenURI_len, tokenURI: felt*) = rtwrk_token_uri(tokenId);
    return (tokenURI_len, tokenURI);
}

@view
func owner{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (owner: felt) {
    let (owner: felt) = Ownable.owner();
    return (owner,);
}

@view
func rtwrkThemeAuctionContractAddress{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() -> (address: felt) {
    let (address: felt) = rtwrk_theme_auction_address.read();
    return (address=address);
}

@view
func rtwrkStepsCount{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    rtwrkId: Uint256
) -> (count: felt) {
    let (count) = rtwrk_steps_count(rtwrkId);
    return (count=count);
}

@view
func totalSupply{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}() -> (
    totalSupply: Uint256
) {
    let (totalSupply: Uint256) = ERC721Enumerable.total_supply();
    return (totalSupply=totalSupply);
}

func get_all_rtwrks_owned{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    owner: felt, index: felt, balance: felt, rtwrks: felt*
) -> () {
    if (index == balance) {
        return ();
    }
    let (tokenId: Uint256) = ERC721Enumerable.token_of_owner_by_index(
        owner=owner, index=Uint256(low=index, high=0)
    );
    assert rtwrks[index] = tokenId.low;
    return get_all_rtwrks_owned(owner, index + 1, balance, rtwrks);
}

@view
func rtwrksOwned{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(owner: felt) -> (
    rtwrks_len: felt, rtwrks: felt*
) {
    alloc_locals;
    let (rtwrks: felt*) = alloc();
    let (balance: Uint256) = ERC721.balance_of(owner);
    get_all_rtwrks_owned(owner, 0, balance.low, rtwrks);
    return (rtwrks_len=balance.low, rtwrks=rtwrks);
}

@view
func rtwrkStep{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    tokenId: Uint256
) -> (step: felt) {
    let (step: felt) = rtwrk_chosen_step.read(tokenId);
    return (step=step);
}

//
// Externals
//

@external
func approve{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    to: felt, tokenId: Uint256
) {
    ERC721.approve(to, tokenId);
    return ();
}

@external
func setApprovalForAll{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    operator: felt, approved: felt
) {
    ERC721.set_approval_for_all(operator, approved);
    return ();
}

@external
func transferFrom{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    from_: felt, to: felt, tokenId: Uint256
) {
    ERC721Enumerable.transfer_from(from_, to, tokenId);
    return ();
}

@external
func safeTransferFrom{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    from_: felt, to: felt, tokenId: Uint256, data_len: felt, data: felt*
) {
    ERC721Enumerable.safe_transfer_from(from_, to, tokenId, data_len, data);
    return ();
}

@external
func mint{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    to: felt, tokenId: Uint256
) {
    alloc_locals;

    let (auction_contract_address) = rtwrk_theme_auction_address.read();
    with_attr error_message(
            "Auction contract address has not been set yet in Rtwrk ERC721 contract") {
        assert_not_zero(auction_contract_address);
    }
    let (caller) = get_caller_address();
    with_attr error_message("Mint can only be called by the auction contract") {
        assert auction_contract_address = caller;
    }

    ERC721Enumerable._mint(to, tokenId);

    return ();
}

@external
func setContractURIHash{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    hash_len: felt, hash: felt*
) {
    Ownable.assert_only_owner();
    contract_uri_hash.write(0, hash[0]);
    contract_uri_hash.write(1, hash[1]);
    contract_uri_hash.write(2, hash[2]);
    return ();
}

@external
func selectRtwrkStep{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    tokenId: Uint256, step: felt
) {
    ERC721.assert_only_token_owner(tokenId);
    let (max_steps) = rtwrk_steps_count(tokenId);
    with_attr error_message("Max step for this rtwrk is {max_steps}") {
        assert_le(step, max_steps);
    }
    rtwrk_chosen_step.write(tokenId, step);
    return ();
}

@external
func setRtwrkThemeAuctionContractAddress{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}(address: felt) -> () {
    Ownable.assert_only_owner();
    rtwrk_theme_auction_address.write(address);
    return ();
}

@external
func transferOwnership{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    newOwner: felt
) {
    Ownable.transfer_ownership(newOwner);
    return ();
}

@external
func renounceOwnership{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    Ownable.renounce_ownership();
    return ();
}

// Proxy upgrade

@external
func upgradeImplementation{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    new_implementation: felt
) {
    Proxy.assert_only_admin();
    Proxy._set_implementation_hash(new_implementation);
    return ();
}

@external
func setProxyAdmin{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(address: felt) {
    Proxy.assert_only_admin();
    Proxy._set_admin(address);
    return ();
}
