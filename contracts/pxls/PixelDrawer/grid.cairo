%lang starknet
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bool import TRUE, FALSE

from pxls.utils.colors import Color, PixelColor, assert_valid_color
from pxls.PixelDrawer.access import assert_pixel_owner
from pxls.PixelDrawer.colorization import (
    Colorization,
    UserColorizations,
    get_all_drawing_user_colorizations,
)
from pxls.PixelDrawer.storage import current_drawing_round, pixel_erc721
from pxls.PixelDrawer.round import get_drawing_timestamp
from pxls.PixelDrawer.palette import get_palette_color
from pxls.interfaces import IPixelERC721

const COLOR_SET_BIT_SIZE = 1
const COLOR_COMPONENT_BIT_SIZE = 8

func get_grid{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    round : felt, max_supply : felt
) -> (grid_len : felt, grid : felt*):
    alloc_locals
    # Let's get all colorizations for this round
    let (
        user_colorizations_len : felt, user_colorizations : UserColorizations*
    ) = get_all_drawing_user_colorizations(round)

    let (grid : felt*) = alloc()

    fill_grid(grid, max_supply, 0, user_colorizations_len, user_colorizations)

    return (max_supply * 4, grid)
end

func fill_grid{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    grid : felt*,
    max_supply : felt,
    current_pixel_index : felt,
    user_colorizations_len : felt,
    user_colorizations : UserColorizations*,
):
    if current_pixel_index == max_supply:
        return ()
    end
    let (pixel_color : PixelColor) = get_pixel_color_from_pixel_index(
        current_pixel_index, user_colorizations_len, user_colorizations
    )
    assert grid[4 * current_pixel_index] = pixel_color.set
    assert grid[4 * current_pixel_index + 1] = pixel_color.color.red
    assert grid[4 * current_pixel_index + 2] = pixel_color.color.green
    assert grid[4 * current_pixel_index + 3] = pixel_color.color.blue

    return fill_grid(
        grid, max_supply, current_pixel_index + 1, user_colorizations_len, user_colorizations
    )
end

func get_pixel_color_from_pixel_index{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}(pixel_index : felt, user_colorizations_len : felt, user_colorizations : UserColorizations*) -> (
    pixel_color : PixelColor
):
    let current_pixel_color = PixelColor(set=FALSE, color=Color(0, 0, 0))
    _get_pixel_color_from_pixel_index(
        pixel_index, current_pixel_color, user_colorizations_len, user_colorizations
    )
    return _get_pixel_color_from_pixel_index(
        pixel_index, current_pixel_color, user_colorizations_len, user_colorizations
    )
end

func _get_pixel_color_from_pixel_index{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}(
    pixel_index : felt,
    current_pixel_color : PixelColor,
    user_colorizations_len : felt,
    user_colorizations : UserColorizations*,
) -> (pixel_color : PixelColor):
    if user_colorizations_len == 0:
        return (current_pixel_color)
    end
    let user_colorization = user_colorizations[0]
    let (new_pixel_color : PixelColor) = _get_pixel_color_from_colorization(
        pixel_index,
        current_pixel_color,
        user_colorization.colorizations_len,
        user_colorization.colorizations,
    )
    return _get_pixel_color_from_pixel_index(
        pixel_index,
        new_pixel_color,
        user_colorizations_len - 1,
        user_colorizations + UserColorizations.SIZE,
    )
end

func _get_pixel_color_from_colorization{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}(
    pixel_index : felt,
    current_pixel_color : PixelColor,
    colorizations_len : felt,
    colorizations : Colorization*,
) -> (pixel_color : PixelColor):
    if colorizations_len == 0:
        return (current_pixel_color)
    end
    let colorization = colorizations[0]
    if colorization.pixel_index == pixel_index:
        let (color) = get_palette_color(colorization.color_index)
        let new_pixel_color = PixelColor(set=TRUE, color=color)
        return _get_pixel_color_from_colorization(
            pixel_index, new_pixel_color, colorizations_len - 1, colorizations + Colorization.SIZE
        )
    else:
        return _get_pixel_color_from_colorization(
            pixel_index,
            current_pixel_color,
            colorizations_len - 1,
            colorizations + Colorization.SIZE,
        )
    end
end
