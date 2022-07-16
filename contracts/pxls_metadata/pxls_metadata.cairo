%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.registers import get_label_location
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.alloc import alloc

from caistring.str import (
    Str,
    str_from_literal,
    str_concat_array,
    str_concat,
    str_empty,
)
from libs.colors import Color
from libs.numbers_literals import number_to_literal_dangerous

from contracts.pxls_metadata.svg import svg_from_pixel_grid
from contracts.pxls_metadata.pxls_colors import get_color_palette_name

func get_yes_no_str{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    boolean : felt
) -> (yes_no_str : Str):
    if boolean == TRUE:
        let (yes_string : Str) = str_from_literal('","value":"yes"}')
        return (yes_no_str=yes_string)
    else:
        let (no_string : Str) = str_from_literal('","value":"no"}')
        return (yes_no_str=no_string)
    end
end

func get_palette_trait{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    palette_index : felt, palette_present : felt, is_last_trait : felt
) -> (trait : Str):
    alloc_locals
    let (trait_start : Str) = str_from_literal('{"trait_type":"')

    let (palette_name : Str) = get_color_palette_name(palette_index)

    let (yes_no_str : Str) = get_yes_no_str(palette_present)

    let (trait : Str) = str_concat(trait_start, palette_name)
    let (trait : Str) = str_concat(trait, yes_no_str)

    if is_last_trait == TRUE:
        return (trait=trait)
    else:
        let (comma : Str) = str_from_literal(',')
        let (trait : Str) = str_concat(trait, comma)
        return (trait=trait)
    end
end

func get_pxl_json_metadata{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    grid_size : felt, pixel_index : felt, pixel_data_len : felt, pixel_data : felt*
) -> (pxl_json_metadata : Str):
    alloc_locals

    let (json_start : Str) = str_from_literal('{"name":"#')
    let (pixel_index_literal) = number_to_literal_dangerous(pixel_index + 1)  # starts at 1
    let (pixel_index_str : Str) = str_from_literal(pixel_index_literal)
    let (attributes_start : Str) = str_from_literal('","attributes":[')
    let (attribute_cyan : Str) = get_palette_trait(0, pixel_data[0], FALSE)
    let (attribute_blue : Str) = get_palette_trait(1, pixel_data[1], FALSE)
    let (attribute_magenta : Str) = get_palette_trait(2, pixel_data[2], FALSE)
    let (attribute_red : Str) = get_palette_trait(3, pixel_data[3], FALSE)
    let (attribute_yellow : Str) = get_palette_trait(4, pixel_data[4], FALSE)
    let (attribute_green : Str) = get_palette_trait(5, pixel_data[5], TRUE)
    let (attributes_end : Str) = str_from_literal(',"image":"')

    # let (svg_image : Str) = svg_from_pixel_grid(grid_size, pixel_data_len - 6, pixel_data + 6)
    let (svg_image : Str) = str_from_literal('<svg></svg>')

    let (json_end : Str) = str_from_literal('"}')

    let (str_array : Str*) = alloc()
    assert str_array[0] = json_start
    assert str_array[1] = pixel_index_str
    assert str_array[2] = attributes_start
    assert str_array[3] = attribute_cyan
    assert str_array[4] = attribute_blue
    assert str_array[5] = attribute_magenta
    assert str_array[6] = attribute_red
    assert str_array[7] = attribute_yellow
    assert str_array[8] = attribute_green
    assert str_array[9] = attributes_end
    assert str_array[10] = svg_image
    assert str_array[11] = json_end

    let (pxl_json_metadata : Str) = str_concat_array(12, str_array)

    return (pxl_json_metadata=pxl_json_metadata)
end
