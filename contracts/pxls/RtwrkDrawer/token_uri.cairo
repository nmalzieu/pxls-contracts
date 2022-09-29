%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.registers import get_label_location
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.alloc import alloc

from caistring.str import literal_concat_known_length_dangerous, literal_from_number

from pxls.utils.colors import Color
from pxls.RtwrkDrawer.svg import append_svg_from_pixel_grid

func get_rtwrk_token_uri{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    grid_size: felt, rtwrk_id: felt, grid_len: felt, grid: felt*
) -> (token_uri_len: felt, token_uri: felt*) {
    alloc_locals;

    let (token_uri: felt*) = alloc();
    assert token_uri[0] = 'data:application/json;';
    assert token_uri[1] = 'charset=utf-8,{"name":"%23';  // json start
    let (pixel_index_literal) = literal_from_number(rtwrk_id);
    assert token_uri[2] = pixel_index_literal;
    assert token_uri[3] = '","attributes":[]';  // no attributes for now
    assert token_uri[4] = ',"image":"data:';
    assert token_uri[5] = 'image/svg+xml,<?xml version=';
    assert token_uri[6] = '\"1.0\" encoding=\"UTF-8\"?>';

    // Grid array is just the pixel data minus the 6 first
    // felts which define which palettes compose the pxl
    let (token_uri_len) = append_svg_from_pixel_grid(
        grid_size=grid_size,
        grid_array_len=grid_len,
        grid_array=grid,
        destination_len=7,
        destination=token_uri,
    );

    assert token_uri[token_uri_len] = '"}';
    return (token_uri_len=token_uri_len + 1, token_uri=token_uri);
}
