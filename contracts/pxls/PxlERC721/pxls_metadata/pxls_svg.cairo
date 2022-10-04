%lang starknet
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.registers import get_label_location
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.math import assert_nn_le, unsigned_div_rem

from caistring.str import literal_concat_known_length_dangerous
from pxls.PxlERC721.pxls_metadata.pxls_colors import get_color
from pxls.utils.colors import Color
from pxls.utils.numbers_literals import number_to_literal_dangerous, number_literal_length

func pixel_coordinates_from_index{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    pixel_index: felt, grid_size: felt
) -> (x: felt, y: felt) {
    let (y, x) = unsigned_div_rem(pixel_index, grid_size);
    return (x=x, y=y);
}

func append_svg_rect_from_pixel{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    x: felt, y: felt, color: Color, destination_len: felt, destination: felt*
) -> (new_destination_len: felt) {
    alloc_locals;

    let rect_start_literal = '<rect width=\"10\" height=\"10\';

    let x_def_literal = '" x=\"';  // length 6
    let (x_literal) = number_to_literal_dangerous(x);  // max length 3 because works up to 400
    let (x_literal_length) = number_literal_length(x);
    let rect_y_literal = '0\" y=\"';  // length 8
    let (y_literal) = number_to_literal_dangerous(y);  // max length 3
    let (y_literal_length) = number_literal_length(y);
    let rect_fill_literal = '0\" fill=\"rgb(';  // length 15
    let comma_literal = ',';  // length 1
    let (red_literal) = number_to_literal_dangerous(color.red);  // max length 3
    let (red_literal_length) = number_literal_length(color.red);
    let (green_literal) = number_to_literal_dangerous(color.green);  // max length 3
    let (green_literal_length) = number_literal_length(color.green);
    let (blue_literal) = number_to_literal_dangerous(color.blue);  // max length 3
    let (blue_literal_length) = number_literal_length(color.blue);
    let rect_end_literal = ')\" />';  // length 6

    // literal_concat_known_length_dangerous must be used only if we know result will
    // be less than 31 characters.

    let (x_to_y_literal) = literal_concat_known_length_dangerous(
        x_def_literal, x_literal, x_literal_length
    );  // 6 + 3 = 9
    let (x_to_y_literal) = literal_concat_known_length_dangerous(x_to_y_literal, rect_y_literal, 8);  // 9 + 8 = 17
    let (x_to_y_literal) = literal_concat_known_length_dangerous(
        x_to_y_literal, y_literal, y_literal_length
    );  // + 3 = 20

    let (fill_to_end_literal) = literal_concat_known_length_dangerous(
        rect_fill_literal, red_literal, red_literal_length
    );  // 15 + 3 = 18
    let (fill_to_end_literal) = literal_concat_known_length_dangerous(
        fill_to_end_literal, comma_literal, 1
    );  // + 1 = 19
    let (fill_to_end_literal) = literal_concat_known_length_dangerous(
        fill_to_end_literal, green_literal, green_literal_length
    );  // + 3 = 22
    let (fill_to_end_literal) = literal_concat_known_length_dangerous(
        fill_to_end_literal, comma_literal, 1
    );  // + 1 = 23
    let (fill_to_end_literal) = literal_concat_known_length_dangerous(
        fill_to_end_literal, blue_literal, blue_literal_length
    );  // + 3 = 26

    assert destination[destination_len] = rect_start_literal;
    assert destination[destination_len + 1] = x_to_y_literal;
    assert destination[destination_len + 2] = fill_to_end_literal;
    assert destination[destination_len + 3] = rect_end_literal;

    return (new_destination_len=destination_len + 4);
}

func append_svg_rects_from_pixel_grid{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}(
    grid_size: felt,
    grid_array_len: felt,
    grid_array: felt*,
    pixel_index: felt,
    destination_len: felt,
    destination: felt*,
) -> (new_destination_len: felt) {
    alloc_locals;
    // A pixel grid is an array of Color arranged in a size x size grid
    // This method generates each svg <rect> for the grid and concatenates them

    // If no more pixel, return the result
    if (grid_array_len == 0) {
        return (new_destination_len=destination_len);
    }

    // Calculate pixel position from its index
    let (x, y) = pixel_coordinates_from_index(pixel_index, grid_size);
    // Get color from array
    let color_index = grid_array[0];
    let (color: Color) = get_color(color_index);
    // Create rect for this pixel
    let (new_destination_len: felt) = append_svg_rect_from_pixel(
        x, y, color, destination_len, destination
    );

    // Tail recursion
    return append_svg_rects_from_pixel_grid(
        grid_size,
        grid_array_len - 1,
        grid_array + 1,
        pixel_index + 1,
        new_destination_len,
        destination,
    );
}

func append_svg_start_from_grid_size{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}(grid_size: felt, destination_len: felt, destination: felt*) -> (new_destination_len: felt) {
    alloc_locals;

    let svg_start_literal = '<svg width=\"';  // length 13
    let (grid_size_literal) = number_to_literal_dangerous(grid_size);  // max length 3
    let (grid_size_literal_length) = number_literal_length(grid_size);
    let svg_height_literal = '0\" height=\"';  // length 13
    let svg_xmlns_literal = '0\" xmlns=';  // length 10
    let svg_uri_literal = '\"http://www.w3.org/2000/svg\" ';
    let svg_end_literal = 'shape-rendering=\"crispEdges\">';

    let (svg_start_to_height) = literal_concat_known_length_dangerous(
        svg_start_literal, grid_size_literal, grid_size_literal_length
    );  // 13 + 3 = 16
    let (svg_start_to_height) = literal_concat_known_length_dangerous(
        svg_start_to_height, svg_height_literal, 13
    );  // 16 + 13 = 29

    let (grid_size_to_xmlns) = literal_concat_known_length_dangerous(
        grid_size_literal, svg_xmlns_literal, 10
    );  // 3 + 10 = 13

    assert destination[destination_len] = svg_start_to_height;
    assert destination[destination_len + 1] = grid_size_to_xmlns;
    assert destination[destination_len + 2] = svg_uri_literal;
    assert destination[destination_len + 3] = svg_end_literal;

    return (new_destination_len=destination_len + 4);
}

func append_svg_from_pixel_grid{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    grid_size: felt,
    grid_array_len: felt,
    grid_array: felt*,
    destination_len: felt,
    destination: felt*,
) -> (new_destination_len: felt) {
    alloc_locals;

    // A pixel grid is an array of colors (represented by their index, a single felt) arranged in a size x size grid

    let (new_destination_len) = append_svg_start_from_grid_size(
        grid_size, destination_len, destination
    );
    let (new_destination_len) = append_svg_rects_from_pixel_grid(
        grid_size, grid_array_len, grid_array, 0, new_destination_len, destination
    );
    // Closing the svg
    assert destination[new_destination_len] = '</svg>';
    return (new_destination_len=new_destination_len + 1);
}
