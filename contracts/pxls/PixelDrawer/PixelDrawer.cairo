%lang starknet
from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.uint256 import Uint256, uint256_sub
from starkware.cairo.common.math import unsigned_div_rem
from starkware.cairo.common.math_cmp import is_le
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.starknet.common.syscalls import get_caller_address, get_block_timestamp
from starkware.cairo.common.alloc import alloc

from openzeppelin.access.ownable import Ownable
from openzeppelin.token.erc721.interfaces.IERC721 import IERC721

from starknet_felt_packing.bits_manipulation import external as bits_manipulation

from pxls.utils.colors import Color, PixelColor, assert_valid_color
from pxls.interfaces import IPixelERC721

const COLOR_SET_BIT_SIZE = 1
const COLOR_COMPONENT_BIT_SIZE = 8

#
# Storage
#

@storage_var
func pixel_erc721() -> (address : felt):
end

@storage_var
func pixel_index_to_pixel_color(drawing_round : felt, pixel_index : felt) -> (color_packed : felt):
end

@storage_var
func drawing_timestamp(drawing_round : felt) -> (timestamp : felt):
end

@storage_var
func current_drawing_round() -> (round : felt):
end

@storage_var
func everyone_can_launch_round() -> (bool : felt):
end

#
# Constructor
#

@constructor
func constructor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    owner : felt, pixel_erc721_address : felt
):
    Ownable.initializer(owner)
    pixel_erc721.write(pixel_erc721_address)
    return ()
end

#
# Getters
#

@view
func pixelERC721Address{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    address : felt
):
    let (address : felt) = pixel_erc721.read()
    return (address=address)
end

@view
func owner{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (owner : felt):
    let (owner : felt) = Ownable.owner()
    return (owner)
end

@view
func currentTokenPixelIndex{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(
    tokenId : Uint256
) -> (pixelIndex : felt):
    let (round) = current_drawing_round.read()
    return token_pixel_index(round, tokenId)
end

@view
func tokenPixelIndex{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(
    round : felt, tokenId : Uint256
) -> (pixelIndex : felt):
    assert_round_exists(round)
    return token_pixel_index(round, tokenId)
end

@view
func pixelColor{bitwise_ptr : BitwiseBuiltin*, pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(
    tokenId : Uint256
) -> (color : PixelColor):
    alloc_locals
    let (round) = current_drawing_round.read()
    let (pixel_index) = token_pixel_index(round, tokenId)
    let (color) = get_pixel_color_from_pixel_index(round, pixel_index)
    return (color=color)
end

@view
func currentDrawingTimestamp{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(
    ) -> (timestamp : felt):
    let (round) = current_drawing_round.read()
    return get_drawing_timestamp(round)
end

@view
func drawingTimestamp{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(
    round : felt
) -> (timestamp : felt):
    assert_round_exists(round)
    return get_drawing_timestamp(round)
end

@view
func currentDrawingRound{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}() -> (
    round : felt
):
    let (round) = current_drawing_round.read()
    return (round=round)
end

@view
func pixelIndexToPixelColor{bitwise_ptr : BitwiseBuiltin*, pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(
    round : felt, pixelIndex : felt
) -> (color : PixelColor):
    let (color) = get_pixel_color_from_pixel_index(round, pixelIndex)
    return (color=color)
end

@view
func getGrid{bitwise_ptr : BitwiseBuiltin*, pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(round : felt) -> (
    grid_len : felt, grid : felt*
):
    alloc_locals
    let (contract_address : felt) = pixel_erc721.read()
    let (max_supply : Uint256) = IPixelERC721.maxSupply(contract_address=contract_address)
    let (local grid : felt*) = alloc()
    let (grid_len : felt) = get_grid(
        round=round, pixel_index=0, max_supply=max_supply.low, grid_len=0, grid=grid
    )
    return (grid_len=grid_len, grid=grid)
end

@view
func everyoneCanLaunchRound{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    ) -> (bool : felt):
    let (bool) = everyone_can_launch_round.read()
    return (bool=bool)
end

#
# Helpers
#

func is_pixel_owner{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    address : felt, pixel_id : Uint256
) -> (owns_pixel : felt):
    let (contract_address : felt) = pixel_erc721.read()
    let (owner_address : felt) = IERC721.ownerOf(
        contract_address=contract_address, tokenId=pixel_id
    )
    if owner_address == address:
        return (owns_pixel=TRUE)
    end
    return (owns_pixel=FALSE)
end

func assert_pixel_owner{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    address : felt, pixel_id : Uint256
):
    let (owns_pixel : felt) = is_pixel_owner(address, pixel_id)
    with_attr error_message("Address does not own pixel: address {address}"):
        assert owns_pixel = TRUE
    end
    return ()
end

func assert_round_exists{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    round : felt
):
    alloc_locals
    let (current_round) = current_drawing_round.read()
    let (round_exists) = is_le(round, current_round)
    with_attr error_message("Round {round} does not exist"):
        assert round_exists = TRUE
    end
    return ()
end

func should_launch_new_round{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    ) -> (should_launch : felt):
    alloc_locals
    let (block_timestamp) = get_block_timestamp()
    let (last_drawing_timestamp) = currentDrawingTimestamp()
    let duration = block_timestamp - last_drawing_timestamp
    # 1 full day in seconds (get_block_timestamp returns timestamp in seconds)
    const DAY_DURATION = 86400
    # if duration >= DAY_DURATION (last drawing lasted 1 day)
    let (should_launch) = is_le(DAY_DURATION, duration)
    return (should_launch=should_launch)
end

func launch_new_round{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    alloc_locals
    let (current_round) = current_drawing_round.read()
    let new_round = current_round + 1
    current_drawing_round.write(new_round)
    let (block_timestamp) = get_block_timestamp()
    drawing_timestamp.write(new_round, block_timestamp)

    return ()
end

func launch_new_round_if_necessary{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}() -> (launched : felt):
    let (should_launch) = should_launch_new_round()
    if should_launch == TRUE:
        launch_new_round()
        # See https://www.cairo-lang.org/docs/how_cairo_works/builtins.html#revoked-implicit-arguments
        tempvar syscall_ptr = syscall_ptr
        tempvar pedersen_ptr = pedersen_ptr
        tempvar range_check_ptr = range_check_ptr
        return (launched=TRUE)
    else:
        tempvar syscall_ptr = syscall_ptr
        tempvar pedersen_ptr = pedersen_ptr
        tempvar range_check_ptr = range_check_ptr
        return (launched=FALSE)
    end
end

func get_grid{bitwise_ptr : BitwiseBuiltin*, syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    round : felt, pixel_index : felt, max_supply : felt, grid_len : felt, grid : felt*
) -> (grid_len : felt):
    if pixel_index == max_supply:
        return (grid_len=grid_len)
    end
    let (pixel_color : PixelColor) = get_pixel_color_from_pixel_index(round, pixel_index)
    assert grid[grid_len] = pixel_color.set
    assert grid[grid_len + 1] = pixel_color.color.red
    assert grid[grid_len + 2] = pixel_color.color.green
    assert grid[grid_len + 3] = pixel_color.color.blue
    return get_grid(
        round=round,
        pixel_index=pixel_index + 1,
        max_supply=max_supply,
        grid_len=grid_len + 4,
        grid=grid,
    )
end

func set_pixel_color{bitwise_ptr : BitwiseBuiltin*, pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(
    tokenId : Uint256, color : Color
):
    alloc_locals
    assert_valid_color(color)

    let (caller_address) = get_caller_address()
    assert_pixel_owner(caller_address, tokenId)

    let (round) = current_drawing_round.read()
    let (pixel_index) = token_pixel_index(round, tokenId)

    # Pixel color is 4 felts : first one is boolean (set / non set) and the three
    # others are color components (R, G, B between 0 and 255)

    let (v1) = bits_manipulation.actual_set_element_at(0, 0, COLOR_SET_BIT_SIZE, TRUE)
    let (v2) = bits_manipulation.actual_set_element_at(
        v1, COLOR_SET_BIT_SIZE, COLOR_COMPONENT_BIT_SIZE, color.red
    )
    let (v3) = bits_manipulation.actual_set_element_at(
        v2, COLOR_SET_BIT_SIZE + COLOR_COMPONENT_BIT_SIZE, COLOR_COMPONENT_BIT_SIZE, color.green
    )
    let (v4) = bits_manipulation.actual_set_element_at(
        v3, COLOR_SET_BIT_SIZE + 2 * COLOR_COMPONENT_BIT_SIZE, COLOR_COMPONENT_BIT_SIZE, color.blue
    )
    pixel_index_to_pixel_color.write(round, pixel_index, v4)
    return ()
end

func set_pixels_colors{bitwise_ptr : BitwiseBuiltin*, pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(
    tokenIds_len : felt, tokenIds : Uint256*, colors_len : felt, colors : Color*
):
    if tokenIds_len == 0:
        return ()
    end
    set_pixel_color(tokenIds[0], colors[0])

    return set_pixels_colors(
        tokenIds_len - 1, tokenIds + Uint256.SIZE, colors_len - 1, colors + Color.SIZE
    )
end

func get_drawing_timestamp{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(
    round : felt
) -> (timestamp : felt):
    let (timestamp) = drawing_timestamp.read(round)
    return (timestamp=timestamp)
end

func token_pixel_index{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(
    round : felt, tokenId : Uint256
) -> (pixelIndex : felt):
    let (round_timestamp) = get_drawing_timestamp(round)

    # We use the fact that (a x + b) % n will visit all
    # integer values in [0,n) exactly once as x iterates
    # through the integers in [0, n), as long as a is coprime with n.
    # 373 is prime so coprime with n and a good choice for a.
    # To introduce "randomness" we choose the round timestamp for b.

    let (erc_address : felt) = pixel_erc721.read()
    let (max_supply : Uint256) = IPixelERC721.maxSupply(contract_address=erc_address)
    let calculation = 373 * tokenId.low + round_timestamp
    let (q, r) = unsigned_div_rem(calculation, max_supply.low)
    return (pixelIndex=r)
end

func get_pixel_color_from_pixel_index{
    bitwise_ptr : BitwiseBuiltin*, pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr
}(round : felt, pixel_index : felt) -> (pixel_color : PixelColor):
    alloc_locals
    # Get the single packed felt from storage and decode it
    let (color_packed) = pixel_index_to_pixel_color.read(round, pixel_index)
    let (set) = bits_manipulation.actual_get_element_at(color_packed, 0, COLOR_SET_BIT_SIZE)
    let (red) = bits_manipulation.actual_get_element_at(
        color_packed, COLOR_SET_BIT_SIZE, COLOR_COMPONENT_BIT_SIZE
    )
    let (green) = bits_manipulation.actual_get_element_at(
        color_packed, COLOR_SET_BIT_SIZE + COLOR_COMPONENT_BIT_SIZE, COLOR_COMPONENT_BIT_SIZE
    )
    let (blue) = bits_manipulation.actual_get_element_at(
        color_packed, COLOR_SET_BIT_SIZE + 2 * COLOR_COMPONENT_BIT_SIZE, COLOR_COMPONENT_BIT_SIZE
    )
    let color = Color(red=red, green=green, blue=blue)
    let pixel_color = PixelColor(set=set, color=color)
    return (pixel_color=pixel_color)
end

#
# Externals
#

@external
func setPixelsColors{bitwise_ptr : BitwiseBuiltin*, pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(
    tokenIds_len : felt, tokenIds : Uint256*, colors_len : felt, colors : Color*
):
    with_attr error_message("tokenId and colors array length don't match"):
        assert tokenIds_len = colors_len
    end
    let (should_launch) = should_launch_new_round()
    with_attr error_message("This drawing round is finished, please launch a new one"):
        assert should_launch = FALSE
    end
    return set_pixels_colors(tokenIds_len, tokenIds, colors_len, colors)
end

@external
func launchNewRoundIfNecessary{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(
    ) -> (launched : felt):
    alloc_locals
    let (bool) = everyone_can_launch_round.read()
    tempvar syscall_ptr = syscall_ptr
    tempvar pedersen_ptr = pedersen_ptr
    tempvar range_check_ptr = range_check_ptr
    if bool == FALSE:
        Ownable.assert_only_owner()
    end
    # Method to just launch a new round with drawing a pixel
    let (launched) = launch_new_round_if_necessary()
    return (launched=launched)
end

@external
func setEveryoneCanLaunchRound{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(
    bool : felt
):
    Ownable.assert_only_owner()
    everyone_can_launch_round.write(bool)
    return ()
end

@external
func transferOwnership{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    newOwner : felt
):
    Ownable.transfer_ownership(newOwner)
    return ()
end

@external
func renounceOwnership{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    Ownable.renounce_ownership()
    return ()
end
