%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.registers import get_label_location
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.alloc import alloc

from libs.colors import Color
from libs.numbers_literals import number_to_literal_dangerous
from caistring.str import literal_concat_known_length_dangerous

from contracts.pxls_metadata.pxls_svg import append_svg_from_pixel_grid
from contracts.pxls_metadata.pxls_colors import get_color_palette_name

func get_yes_no_str{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    boolean : felt
) -> (yes_no_str : felt):
    if boolean == TRUE:
        return (yes_no_str='","value":"yes"}')
    else:
        return (yes_no_str='","value":"no"}')
    end
end

func append_palette_trait{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    palette_index : felt,
    palette_present : felt,
    is_last_trait : felt,
    destination_len : felt,
    destination : felt*,
) -> (new_destination_len : felt):
    alloc_locals
    let trait_start = '{"trait_type":"'

    let (palette_name : felt) = get_color_palette_name(palette_index)

    let (yes_no_str : felt) = get_yes_no_str(palette_present)
    if is_last_trait == FALSE:
        let (yes_no_str : felt) = literal_concat_known_length_dangerous(yes_no_str, ',', 1)
    else:
        let (yes_no_str : felt) = literal_concat_known_length_dangerous(yes_no_str, ']', 1)
    end

    assert destination[destination_len] = trait_start
    assert destination[destination_len + 1] = palette_name
    assert destination[destination_len + 2] = yes_no_str

    return (new_destination_len=destination_len + 3)
end

func get_pxl_json_metadata{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    grid_size : felt, pixel_index : felt, pixel_data_len : felt, pixel_data : felt*
) -> (pxl_json_metadata_len : felt, pxl_json_metadata : felt*):
    alloc_locals

    let (pxl_json_metadata : felt*) = alloc()
    assert pxl_json_metadata[0] = 'data:application/json;'
    assert pxl_json_metadata[1] = 'charset=utf-8,{"name":"%23'  # json start
    let (pixel_index_literal) = number_to_literal_dangerous(pixel_index + 1)  # starts at 1
    assert pxl_json_metadata[2] = pixel_index_literal
    assert pxl_json_metadata[3] = '","attributes":['  # attributes start
    let (pxl_json_metadata_len) = append_palette_trait(
        0, pixel_data[0], FALSE, 4, pxl_json_metadata
    )  # cyan attribute
    let (pxl_json_metadata_len) = append_palette_trait(
        1, pixel_data[1], FALSE, pxl_json_metadata_len, pxl_json_metadata
    )  # blue attribute
    let (pxl_json_metadata_len) = append_palette_trait(
        2, pixel_data[2], FALSE, pxl_json_metadata_len, pxl_json_metadata
    )  # magenta attribute
    let (pxl_json_metadata_len) = append_palette_trait(
        3, pixel_data[3], FALSE, pxl_json_metadata_len, pxl_json_metadata
    )  # red attribute
    let (pxl_json_metadata_len) = append_palette_trait(
        4, pixel_data[4], FALSE, pxl_json_metadata_len, pxl_json_metadata
    )  # yellow attribute
    let (pxl_json_metadata_len) = append_palette_trait(
        5, pixel_data[5], TRUE, pxl_json_metadata_len, pxl_json_metadata
    )  # green attribute

    assert pxl_json_metadata[pxl_json_metadata_len] = ',"image":"data:'
    assert pxl_json_metadata[pxl_json_metadata_len + 1] = 'image/svg+xml,<?xml version="1.'
    assert pxl_json_metadata[pxl_json_metadata_len + 2] = '0" encoding="UTF-8"?>'

    # Grid array is just the pixel data minus the 6 first
    # felts which define which palettes compose the pxl
    let (pxl_json_metadata_len) = append_svg_from_pixel_grid(
        grid_size=grid_size,
        grid_array_len=pixel_data_len - 6,
        grid_array=pixel_data + 6,
        destination_len=pxl_json_metadata_len + 3,
        destination=pxl_json_metadata,
    )

    assert pxl_json_metadata[pxl_json_metadata_len] = '"}'

    return (pxl_json_metadata_len=pxl_json_metadata_len + 1, pxl_json_metadata=pxl_json_metadata)
end
