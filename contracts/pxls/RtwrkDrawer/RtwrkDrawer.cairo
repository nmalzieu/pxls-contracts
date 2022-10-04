%lang starknet
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.bool import FALSE
from starkware.cairo.common.alloc import alloc
from starkware.starknet.common.syscalls import get_caller_address
from starkware.cairo.common.math import assert_le, assert_not_zero

from openzeppelin.access.ownable.library import Ownable
from openzeppelin.upgrades.library import Proxy

from pxls.utils.colors import Color, PixelColor
from pxls.interfaces import IPxlERC721
from pxls.RtwrkDrawer.storage import (
    pxl_erc721_address,
    current_rtwrk_id,
    number_of_pixel_colorizations_per_colorizer,
    number_of_pixel_colorizations_total,
    rtwrk_auction_address,
)
from pxls.RtwrkDrawer.events import pixels_colorized
from pxls.RtwrkDrawer.rtwrk import (
    assert_rtwrk_id_exists,
    get_rtwrk_timestamp,
    assert_current_rtwrk_running,
    launch_new_rtwrk_if_necessary,
    read_theme,
)
from pxls.RtwrkDrawer.access import assert_pxl_owner
from pxls.RtwrkDrawer.colorization import (
    Colorization,
    PixelColorization,
    save_rtwrk_colorization,
    get_all_rtwrk_colorizations,
    get_colorizers,
    count_rtwrk_colorizations,
)
from pxls.RtwrkDrawer.variables import MAX_PIXEL_COLORIZATIONS_PER_COLORIZER
from pxls.RtwrkDrawer.grid import get_grid
from pxls.RtwrkDrawer.original_rtwrks import initialize_original_rtwrks
from pxls.RtwrkDrawer.token_uri import get_rtwrk_token_uri

// @dev The constructor initializing the drawer with important data
// @param owner: The owner of this contract
// @param pxl_erc721_address: The address of the PxlERC721 contract token gating access to the drawer
// @param max_colorizations: The max # of colorizations a pxlr can do in a given rtwrk

@external
func initializer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    proxy_admin: felt, owner: felt, pxl_erc721: felt
) {
    Proxy.initializer(proxy_admin);
    Ownable.initializer(owner);
    pxl_erc721_address.write(pxl_erc721);
    // Writing the "original rtwrks" that happened before regenesis
    initialize_original_rtwrks();
    return ();
}

// ════════════════════════════════════════════════════════════════════════════════════════════════════════════════════
//     @view methods
// ════════════════════════════════════════════════════════════════════════════════════════════════════════════════════

// @notice A method to get back the address of the PixelERC721 contract token gating access to the drawer
// @return address: The address of the PixelERC721 contract

@view
func pxlERC721Address{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    address: felt
) {
    let (address: felt) = pxl_erc721_address.read();
    return (address=address);
}

// @notice A method to get back the owner of this contract (the admin)
// @return owner: The owner of this drawer contract

@view
func owner{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (owner: felt) {
    let (owner: felt) = Ownable.owner();
    return (owner,);
}

// @notice Get the timestamp of the start of the current rtwrk
// @return timestamp: The timestamp of the start of the current rtwrk

@view
func currentRtwrkTimestamp{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}() -> (
    timestamp: felt
) {
    let (rtwrk_id) = current_rtwrk_id.read();
    return get_rtwrk_timestamp(rtwrk_id);
}

// @notice Get the timestamp of the start of any rtwrk
// @param rtwrk_id: Id of the rtwrk we want to get the timestamp of
// @return return_name: The timestamp of the start of the chosen rtwrk

@view
func rtwrkTimestamp{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    rtwrk_id: felt
) -> (timestamp: felt) {
    assert_rtwrk_id_exists(rtwrk_id);
    return get_rtwrk_timestamp(rtwrk_id);
}

// @notice Get the id of the current rtwrk
// @return rtwrk_id: The id of the current rtwrk

@view
func currentRtwrkId{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}() -> (
    rtwrk_id: felt
) {
    let (rtwrk_id) = current_rtwrk_id.read();
    return (rtwrk_id=rtwrk_id);
}

@view
func rtwrkGrid{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    rtwrkId: felt, rtwrkStep: felt
) -> (grid_len: felt, grid: felt*) {
    alloc_locals;
    let (contract_address: felt) = pxl_erc721_address.read();
    let (max_supply: Uint256) = IPxlERC721.maxSupply(contract_address=contract_address);
    let (grid_len: felt, grid: felt*) = get_grid(
        rtwrk_id=rtwrkId, grid_size=max_supply.low, rtwrk_step=rtwrkStep
    );
    return (grid_len=grid_len, grid=grid);
}

@view
func rtwrkTokenUri{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    rtwrkId: felt, rtwrkStep: felt
) -> (tokenUri_len: felt, tokenUri: felt*) {
    alloc_locals;
    let (contract_address: felt) = pxl_erc721_address.read();
    let (max_supply: Uint256) = IPxlERC721.maxSupply(contract_address=contract_address);
    let (grid_size: Uint256) = IPxlERC721.matrixSize(contract_address=contract_address);
    let (grid_len: felt, grid: felt*) = get_grid(
        rtwrk_id=rtwrkId, grid_size=max_supply.low, rtwrk_step=rtwrkStep
    );
    let (token_uri_len: felt, token_uri: felt*) = get_rtwrk_token_uri(
        grid_size=grid_size.low, rtwrk_id=rtwrkId, grid_len=grid_len, grid=grid
    );
    return (tokenUri_len=token_uri_len, tokenUri=token_uri);
}

@view
func numberOfPixelColorizations{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    rtwrkId: felt, pxlId: Uint256
) -> (count: felt) {
    let (count: felt) = number_of_pixel_colorizations_per_colorizer.read(rtwrkId, pxlId);
    return (count,);
}

@view
func totalNumberOfPixelColorizations{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}(rtwrkId: felt) -> (count: felt) {
    let (count: felt) = number_of_pixel_colorizations_total.read(rtwrkId);
    return (count,);
}

@view
func numberOfColorizers{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    rtwrkId: felt, rtwrkStep: felt
) -> (count: felt) {
    assert_rtwrk_id_exists(rtwrkId);
    let (colorizers_len, colorizers: felt*) = get_colorizers(rtwrkId, rtwrkStep);
    return (count=colorizers_len);
}

@view
func colorizers{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    rtwrkId: felt, rtwrkStep: felt
) -> (colorizers_len: felt, colorizers: felt*) {
    assert_rtwrk_id_exists(rtwrkId);
    return get_colorizers(rtwrkId, rtwrkStep);
}

@view
func rtwrkTheme{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(rtwrkId: felt) -> (
    theme_len: felt, theme: felt*
) {
    return read_theme(rtwrkId);
}

@view
func rtwrkStepsCount{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    rtwrkId: felt
) -> (steps_count: felt) {
    let (count) = count_rtwrk_colorizations(rtwrkId, 0);
    return (steps_count=count);
}

@view
func maxPixelColorizationsPerColorizer() -> (max: felt) {
    return (max=MAX_PIXEL_COLORIZATIONS_PER_COLORIZER);
}

@view
func rtwrkThemeAuctionContractAddress{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() -> (address: felt) {
    let (address: felt) = rtwrk_auction_address.read();
    return (address=address);
}

//
// Externals
//

@external
func colorizePixels{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    pxlId: Uint256, pixel_colorizations_len: felt, pixel_colorizations: PixelColorization*
) {
    alloc_locals;
    let (caller_address) = get_caller_address();

    assert_pxl_owner(caller_address, pxlId);
    assert_current_rtwrk_running();

    let (rtwrk_id) = current_rtwrk_id.read();

    save_rtwrk_colorization(rtwrk_id, pxlId, pixel_colorizations_len, pixel_colorizations);

    pixels_colorized.emit(
        pxl_id=pxlId,
        account_address=caller_address,
        pixel_colorizations_len=pixel_colorizations_len,
        pixel_colorizations=pixel_colorizations,
    );

    return ();
}

@external
func launchNewRtwrk{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    theme_len: felt, theme: felt*
) -> () {
    alloc_locals;
    with_attr error_message("Theme too long") {
        assert_le(theme_len, 5);
    }
    let (auction_contract_address) = rtwrk_auction_address.read();

    with_attr error_message("Auction contract address has not been set yet in drawer contract") {
        assert_not_zero(auction_contract_address);
    }

    let (caller) = get_caller_address();

    with_attr error_message("Only the auction contract can launch a new rtwrk") {
        assert auction_contract_address = caller;
    }
    // Method to just launch a new rtwrk with drawing a pixel
    launch_new_rtwrk_if_necessary(theme_len, theme);
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

@external
func setRtwrkThemeAuctionContractAddress{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}(address: felt) -> () {
    Ownable.assert_only_owner();
    rtwrk_auction_address.write(address);
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
