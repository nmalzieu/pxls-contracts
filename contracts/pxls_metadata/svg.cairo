%lang starknet
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.registers import get_label_location
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.math import assert_nn_le, unsigned_div_rem

from contracts.pxls_metadata.pxls_colors import get_color
from caistring.str import (
    Str,
    str_from_literal,
    str_concat_array,
    str_concat,
    str_empty,
    literal_concat_known_length_dangerous,
)
from libs.colors import Color
from libs.numbers_literals import number_to_literal_dangerous, number_literal_length

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

    let (x_literal) = number_to_literal_dangerous(x)  # max length 3 because works up to 400
    let rect_y_literal = '0" y="'  # length 6
    let (y_literal) = number_to_literal_dangerous(y)  # max length 3
    let (y_literal_length) = number_literal_length(y)
    let rect_fill_literal = '0" fill="rgb('  # length 13
    let comma_literal = ','  # length 1
    let (red_literal) = number_to_literal_dangerous(color.red)  # max length 3
    let (green_literal) = number_to_literal_dangerous(color.green)  # max length 3
    let (green_literal_length) = number_literal_length(color.green)
    let (blue_literal) = number_to_literal_dangerous(color.blue)  # max length 3
    let (blue_literal_length) = number_literal_length(color.blue)
    let rect_end_literal = ')" />'  # length 5

    # literal_concat_known_length_dangerous must be used only if we know result will
    # be less than 31 characters.

    let (x_to_fill_literal) = literal_concat_known_length_dangerous(x_literal, rect_y_literal, 6)  # 3 + 6 = 9
    let (x_to_fill_literal) = literal_concat_known_length_dangerous(
        x_to_fill_literal, y_literal, y_literal_length
    )  # + 3 = 12
    let (x_to_fill_literal) = literal_concat_known_length_dangerous(
        x_to_fill_literal, rect_fill_literal, 13
    )  # + 13 = 25

    let (x_to_fill_str : Str) = str_from_literal(x_to_fill_literal)

    let (red_to_end_literal) = literal_concat_known_length_dangerous(red_literal, comma_literal, 1)  # 3 + 1 = 4
    let (red_to_end_literal) = literal_concat_known_length_dangerous(
        red_to_end_literal, green_literal, green_literal_length
    )  # + 3 = 7
    let (red_to_end_literal) = literal_concat_known_length_dangerous(
        red_to_end_literal, comma_literal, 1
    )  # + 1 = 8
    let (red_to_end_literal) = literal_concat_known_length_dangerous(
        red_to_end_literal, blue_literal, blue_literal_length
    )  # + 3 = 11
    let (red_to_end_literal) = literal_concat_known_length_dangerous(
        red_to_end_literal, rect_end_literal, 5
    )  # + 5 = 16

    let (red_to_end_str : Str) = str_from_literal(red_to_end_literal)

    let rect_start_str = Str(2, cast(rect_start_x_location, felt*))
    let (svg_rect_str : Str) = str_concat(rect_start_str, x_to_fill_str)
    let (svg_rect_str : Str) = str_concat(svg_rect_str, red_to_end_str)

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
    let (grid_size_literal) = number_to_literal_dangerous(grid_size)
    let (grid_size_str : Str) = str_from_literal(grid_size_literal)
    let (svg_height : Str) = str_from_literal('0" height="')
    let (svg_xmlns : Str) = str_from_literal('0" xmlns="http://www.w3.org/200')
    let (svg_end : Str) = str_from_literal('0/svg">')

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
    let (svg_rects : Str) = svg_rects_from_pixel_grid(
        grid_size, grid_array_len, grid_array, 0, empty_str
    )

    let (svg_end : Str) = str_from_literal('</svg>')

    let (svg_unclosed : Str) = str_concat(svg_start, svg_rects)
    let (svg_str : Str) = str_concat(svg_unclosed, svg_end)
    return (svg_str=svg_str)
end
