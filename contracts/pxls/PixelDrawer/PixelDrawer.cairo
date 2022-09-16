%lang starknet
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.bool import FALSE
from starkware.cairo.common.alloc import alloc
from starkware.starknet.common.syscalls import get_caller_address
from starkware.cairo.common.math import assert_le

from openzeppelin.access.ownable.library import Ownable

from pxls.utils.colors import Color, PixelColor
from pxls.interfaces import IPixelERC721
from pxls.PixelDrawer.storage import (
    pixel_erc721,
    current_drawing_round,
    everyone_can_launch_round,
    max_colorizations_per_token,
    number_of_colorizations_per_token,
    number_of_colorizations_total,
)
from pxls.PixelDrawer.round import (
    assert_round_exists,
    get_drawing_timestamp,
    assert_current_round_running,
    launch_new_round_if_necessary,
    read_theme,
)
from pxls.PixelDrawer.access import assert_pixel_owner
from pxls.PixelDrawer.colorization import (
    UserColorizations,
    Colorization,
    save_drawing_user_colorizations,
    get_all_drawing_user_colorizations,
    get_colorizers,
)
from pxls.PixelDrawer.grid import get_grid

//
// Constructor
//

@constructor
func constructor{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    owner: felt, pixel_erc721_address: felt, max_colorizations: felt
) {
    Ownable.initializer(owner);
    pixel_erc721.write(pixel_erc721_address);
    // Written during deploy but could be changed later
    max_colorizations_per_token.write(max_colorizations);
    return ();
}

//
// Getters
//

@view
func pixelERC721Address{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    address: felt
) {
    let (address: felt) = pixel_erc721.read();
    return (address=address);
}

@view
func owner{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (owner: felt) {
    let (owner: felt) = Ownable.owner();
    return (owner,);
}

@view
func currentDrawingTimestamp{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}() -> (
    timestamp: felt
) {
    let (round) = current_drawing_round.read();
    return get_drawing_timestamp(round);
}

@view
func drawingTimestamp{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    round: felt
) -> (timestamp: felt) {
    assert_round_exists(round);
    return get_drawing_timestamp(round);
}

@view
func currentDrawingRound{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}() -> (
    round: felt
) {
    let (round) = current_drawing_round.read();
    return (round=round);
}

@view
func currentDrawingPixelColor{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    pixelIndex: felt
) -> (color: PixelColor) {
    alloc_locals;
    let (round) = current_drawing_round.read();
    return pixelColor(round, pixelIndex, 0);
}

@view
func pixelColor{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    round: felt, pixelIndex: felt, step: felt
) -> (color: PixelColor) {
    alloc_locals;
    let (contract_address: felt) = pixel_erc721.read();
    let (max_supply: Uint256) = IPixelERC721.maxSupply(contract_address=contract_address);
    with_attr error_message("Max pixel index value is {max_supply}") {
        assert_le(pixelIndex, max_supply.low);
    }
    let (grid_len: felt, grid: felt*) = get_grid(round=round, max_supply=max_supply.low, step=step);
    let color = PixelColor(
        set=grid[4 * pixelIndex],
        color=Color(grid[4 * pixelIndex + 1], grid[4 * pixelIndex + 2], grid[4 * pixelIndex + 3]),
    );
    return (color=color);
}

@view
func getGrid{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    round: felt, step: felt
) -> (grid_len: felt, grid: felt*) {
    alloc_locals;
    let (contract_address: felt) = pixel_erc721.read();
    let (max_supply: Uint256) = IPixelERC721.maxSupply(contract_address=contract_address);
    let (grid_len: felt, grid: felt*) = get_grid(round=round, max_supply=max_supply.low, step=step);
    return (grid_len=grid_len, grid=grid);
}

@view
func everyoneCanLaunchRound{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    bool: felt
) {
    let (bool) = everyone_can_launch_round.read();
    return (bool=bool);
}

@view
func numberOfColorizations{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    round: felt, tokenId: Uint256
) -> (count: felt) {
    let (count: felt) = number_of_colorizations_per_token.read(round, tokenId);
    return (count,);
}

@view
func totalNumberOfColorizations{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    round: felt
) -> (count: felt) {
    let (count: felt) = number_of_colorizations_total.read(round);
    return (count,);
}

@view
func maxColorizationsPerToken{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    ) -> (max: felt) {
    let (max) = max_colorizations_per_token.read();
    return (max,);
}

@view
func numberOfColorizers{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    drawing_round: felt, step: felt
) -> (count: felt) {
    assert_round_exists(drawing_round);
    let (colorizers_len, colorizers: felt*) = get_colorizers(drawing_round, step);
    return (count=colorizers_len);
}

@view
func getColorizers{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    drawing_round: felt, step: felt
) -> (colorizers_len: felt, colorizers: felt*) {
    assert_round_exists(drawing_round);
    return get_colorizers(drawing_round, step);
}

@view
func drawingTheme{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    drawing_round: felt
) -> (theme_len: felt, theme: felt*) {
    return read_theme(drawing_round);
}

//
// Externals
//

@external
func colorizePixels{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    tokenId: Uint256, colorizations_len: felt, colorizations: Colorization*
) {
    let (caller_address) = get_caller_address();

    assert_pixel_owner(caller_address, tokenId);
    assert_current_round_running();

    let (round) = current_drawing_round.read();

    save_drawing_user_colorizations(round, tokenId, colorizations_len, colorizations);
    return ();
}

@external
func launchNewRoundIfNecessary{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    theme_len: felt, theme: felt*
) -> (launched: felt) {
    alloc_locals;
    with_attr error_message("Theme too long") {
        assert_le(theme_len, 5);
    }
    let (bool) = everyone_can_launch_round.read();
    tempvar syscall_ptr = syscall_ptr;
    tempvar pedersen_ptr = pedersen_ptr;
    tempvar range_check_ptr = range_check_ptr;
    if (bool == FALSE) {
        Ownable.assert_only_owner();
    }
    // Method to just launch a new round with drawing a pixel
    let (launched) = launch_new_round_if_necessary(theme_len, theme);
    return (launched=launched);
}

@external
func setEveryoneCanLaunchRound{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    bool: felt
) {
    Ownable.assert_only_owner();
    everyone_can_launch_round.write(bool);
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
func setMaxColorizationsPerToken{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    new_max: felt
) {
    Ownable.assert_only_owner();
    max_colorizations_per_token.write(new_max);
    return ();
}
