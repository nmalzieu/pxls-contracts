%lang starknet
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.bool import FALSE
from starkware.cairo.common.alloc import alloc
from starkware.starknet.common.syscalls import get_caller_address
from starkware.cairo.common.math import assert_le

from openzeppelin.access.ownable.library import Ownable

from pxls.utils.colors import Color, PixelColor
from pxls.interfaces import IPxlERC721
from pxls.RtwrkDrawer.storage import (
    pxl_erc721_address,
    current_rtwrk_id,
    everyone_can_launch_rtwrk,
    max_pixel_colorizations_per_colorizer,
    number_of_pixel_colorizations_per_colorizer,
    number_of_pixel_colorizations_total,
)
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
)
from pxls.RtwrkDrawer.grid import get_grid

// @dev The constructor initializing the drawer with important data
// @param owner: The owner of this contract
// @param pxl_erc721_address: The address of the PxlERC721 contract token gating access to the drawer
// @param max_colorizations: The max # of colorizations a pxlr can do in a given rtwrk

@constructor
func constructor{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    owner: felt, pxl_erc721: felt, max_pixel_colorizations_per_colorizer_value: felt
) {
    Ownable.initializer(owner);
    pxl_erc721_address.write(pxl_erc721);
    // Written during deploy but could be changed later
    max_pixel_colorizations_per_colorizer.write(max_pixel_colorizations_per_colorizer_value);
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
func currentRtwrkPixelColor{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    pixelIndex: felt
) -> (color: PixelColor) {
    alloc_locals;
    let (rtwrk_id) = current_rtwrk_id.read();
    return pixelColor(rtwrk_id, pixelIndex, 0);
}

@view
func pixelColor{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    rtwrkId: felt, pixelIndex: felt, rtwrkStep: felt
) -> (color: PixelColor) {
    alloc_locals;
    let (contract_address: felt) = pxl_erc721_address.read();
    let (max_supply: Uint256) = IPxlERC721.maxSupply(contract_address=contract_address);
    with_attr error_message("Max pixel index value is {max_supply}") {
        assert_le(pixelIndex, max_supply.low);
    }
    let (grid_len: felt, grid: felt*) = get_grid(
        rtwrk_id=rtwrkId, grid_size=max_supply.low, rtwrk_step=rtwrkStep
    );
    let color = PixelColor(
        set=grid[4 * pixelIndex],
        color=Color(grid[4 * pixelIndex + 1], grid[4 * pixelIndex + 2], grid[4 * pixelIndex + 3]),
    );
    return (color=color);
}

@view
func getGrid{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
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
func everyoneCanLaunchRtwrk{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    bool: felt
) {
    let (bool) = everyone_can_launch_rtwrk.read();
    return (bool=bool);
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
func maxPixelColorizationsPerColorizer{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() -> (max: felt) {
    let (max) = max_pixel_colorizations_per_colorizer.read();
    return (max,);
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
func getColorizers{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
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

//
// Externals
//

@external
func colorizePixels{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    pxlId: Uint256, pixel_colorizations_len: felt, pixel_colorizations: PixelColorization*
) {
    let (caller_address) = get_caller_address();

    assert_pxl_owner(caller_address, pxlId);
    assert_current_rtwrk_running();

    let (rtwrk_id) = current_rtwrk_id.read();

    save_rtwrk_colorization(rtwrk_id, pxlId, pixel_colorizations_len, pixel_colorizations);
    return ();
}

@external
func launchNewRtwrkIfNecessary{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    theme_len: felt, theme: felt*
) -> (launched: felt) {
    alloc_locals;
    with_attr error_message("Theme too long") {
        assert_le(theme_len, 5);
    }
    let (bool) = everyone_can_launch_rtwrk.read();
    tempvar syscall_ptr = syscall_ptr;
    tempvar pedersen_ptr = pedersen_ptr;
    tempvar range_check_ptr = range_check_ptr;
    if (bool == FALSE) {
        Ownable.assert_only_owner();
    }
    // Method to just launch a new rtwrk with drawing a pixel
    let (launched) = launch_new_rtwrk_if_necessary(theme_len, theme);
    return (launched=launched);
}

@external
func setEveryoneCanLaunchRtwrk{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    bool: felt
) {
    Ownable.assert_only_owner();
    everyone_can_launch_rtwrk.write(bool);
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
func setMaxColorizationsPerColorizer{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}(new_max: felt) {
    Ownable.assert_only_owner();
    max_pixel_colorizations_per_colorizer.write(new_max);
    return ();
}
