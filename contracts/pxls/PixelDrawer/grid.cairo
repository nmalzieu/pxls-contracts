%lang starknet
from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.uint256 import Uint256
from starkware.starknet.common.syscalls import get_caller_address
from starkware.cairo.common.bool import FALSE, TRUE
from starkware.cairo.common.math import unsigned_div_rem
from starknet_felt_packing.bits_manipulation import external as bits_manipulation

from pxls.utils.colors import Color, PixelColor, assert_valid_color
from pxls.PixelDrawer.access import assert_pixel_owner
from pxls.PixelDrawer.storage import current_drawing_round, pixel_index_to_pixel_color, pixel_erc721
from pxls.PixelDrawer.round import get_drawing_timestamp
from pxls.interfaces import IPixelERC721

const COLOR_SET_BIT_SIZE = 1
const COLOR_COMPONENT_BIT_SIZE = 8

func get_grid{
    bitwise_ptr : BitwiseBuiltin*, syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}(round : felt, pixel_index : felt, max_supply : felt, grid_len : felt, grid : felt*) -> (
    grid_len : felt
):
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

func set_pixel_color{
    bitwise_ptr : BitwiseBuiltin*, pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr
}(tokenId : Uint256, color : Color):
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

func set_pixels_colors{
    bitwise_ptr : BitwiseBuiltin*, pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr
}(tokenIds_len : felt, tokenIds : Uint256*, colors_len : felt, colors : Color*):
    if tokenIds_len == 0:
        return ()
    end
    set_pixel_color(tokenIds[0], colors[0])

    return set_pixels_colors(
        tokenIds_len - 1, tokenIds + Uint256.SIZE, colors_len - 1, colors + Color.SIZE
    )
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
