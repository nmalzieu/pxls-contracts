%lang starknet
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.registers import get_label_location
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.math import assert_nn_le, unsigned_div_rem

from contracts.pxls_metadata.pxls_colors import get_color
from caistring.str import (
    Str,
    str_from_number,
    str_from_literal,
    str_concat_array,
    str_concat,
    str_empty,
)
from libs.colors import Color

func pixel_coordinates_from_index{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}(pixel_index : felt, grid_size : felt) -> (x : felt, y : felt):
    let (y, x) = unsigned_div_rem(pixel_index, grid_size)
    return (x=x, y=y)
end

func svg_rect_from_pixel{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    x : felt, y : felt, color : Color
) -> (svg_rect_str : Str):
    alloc_locals

    let (rect_start_x_location) = get_label_location(rect_start_x_label)
    let (comma) = str_from_literal(',')
    let (x_str : Str) = str_from_number(x * 10)  # Since our pixels have dimension 10
    let (rect_y : Str) = str_from_literal('" y="')
    let (y_str : Str) = str_from_number(y * 10)  # Since our pixels have dimension 10
    let (rect_fill : Str) = str_from_literal('" fill="rgb(')
    let (red_str : Str) = str_from_number(color.red)
    let (green_str : Str) = str_from_number(color.green)
    let (blue_str : Str) = str_from_number(color.blue)
    let (rect_end : Str) = str_from_literal(')" />')

    let (str_array : Str*) = alloc()
    assert str_array[0] = Str(2, cast(rect_start_x_location, felt*))
    assert str_array[1] = x_str
    assert str_array[2] = rect_y
    assert str_array[3] = y_str
    assert str_array[4] = rect_fill
    assert str_array[5] = red_str
    assert str_array[6] = comma
    assert str_array[7] = green_str
    assert str_array[8] = comma
    assert str_array[9] = blue_str
    assert str_array[10] = rect_end

    let (svg_rect_str : Str) = str_concat_array(11, str_array)

    return (svg_rect_str=svg_rect_str)

    rect_start_x_label:
    dw '<rect width="10" height="10" x='
    dw '"'
end

func svg_rects_from_pixel_grid{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    grid_size : felt,
    grid_array_len : felt,
    grid_array : felt*,
    pixel_index : felt,
    current_str : Str,
) -> (svg_rects_str : Str):
    alloc_locals
    # A pixel grid is an array of Color arranged in a size x size grid
    # This method generates each svg <rect> for the grid and concatenates them

    # If no more pixel, return the result
    if grid_array_len == 0:
        return (svg_rects_str=current_str)
    end

    # Calculate pixel position from its index
    let (x, y) = pixel_coordinates_from_index(pixel_index, grid_size)
    # Get color from array
    let color_index = grid_array[0]
    let (color : Color) = get_color(color_index)
    # Create rect for this pixel
    let (pixel_rect_str : Str) = svg_rect_from_pixel(x=x, y=y, color=color)

    # Tail recursion
    let (new_current_str : Str) = str_concat(current_str, pixel_rect_str)
    return svg_rects_from_pixel_grid(
        grid_size, grid_array_len - 1, grid_array + 1, pixel_index + 1, new_current_str
    )
end

func svg_start_from_grid_size{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    grid_size : felt
) -> (svg_start_str : Str):
    alloc_locals

    let (svg_start : Str) = str_from_literal('<svg width="')
    let (grid_size_str : Str) = str_from_number(10 * grid_size)
    let (svg_height : Str) = str_from_literal('" height="')
    let (svg_xmlns : Str) = str_from_literal('" xmlns="http://www.w3.org/2000')
    let (svg_end : Str) = str_from_literal('/svg">')

    let (str_array : Str*) = alloc()
    assert str_array[0] = svg_start
    assert str_array[1] = grid_size_str
    assert str_array[2] = svg_height
    assert str_array[3] = grid_size_str
    assert str_array[4] = svg_xmlns
    assert str_array[5] = svg_end

    let (svg_start_str : Str) = str_concat_array(6, str_array)

    return (svg_start_str=svg_start_str)
end

func svg_from_pixel_grid{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    grid_size : felt, grid_array_len : felt, grid_array : felt*
) -> (svg_str : Str):
    alloc_locals

    # A pixel grid is an array of colors (represented by their index, a single felt) arranged in a size x size grid
    let (svg_start : Str) = svg_start_from_grid_size(grid_size)
    
    let (empty_str : Str) = str_empty()
    let (svg_rects : Str) = svg_rects_from_pixel_grid(grid_size, grid_array_len, grid_array, 0, empty_str)

    let (svg_end : Str) = str_from_literal('</svg>')

    let (svg_unclosed : Str) = str_concat(svg_start, svg_rects)
    let (svg_str : Str) = str_concat(svg_unclosed, svg_end)
    return (svg_str=svg_str)
end
