%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.registers import get_label_location
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.memcpy import memcpy

from caistring.str import literal_from_number

from pxls.utils.colors import Color
from pxls.RtwrkDrawer.svg import append_svg_from_pixel_grid
from pxls.RtwrkDrawer.storage import number_of_pixel_colorizations_total
from pxls.RtwrkDrawer.colorization import get_colorizers
from pxls.RtwrkDrawer.rtwrk import read_theme

func get_rtwrk_token_uri{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    grid_size: felt, rtwrk_id: felt, grid_len: felt, grid: felt*
) -> (token_uri_len: felt, token_uri: felt*) {
    alloc_locals;

    let (token_uri: felt*) = alloc();
    assert token_uri[0] = 'data:application/json;charset';
    assert token_uri[1] = '=utf-8,{"name":"Rtwrk%20%23';

    let (pixel_index_literal) = literal_from_number(rtwrk_id);
    assert token_uri[2] = pixel_index_literal;

    assert token_uri[3] = '","description":"';

    let (theme_len, theme: felt*) = read_theme(rtwrk_id);
    memcpy(dst=token_uri + 4, src=theme, len=theme_len);

    let current_len = 4 + theme_len;

    assert token_uri[current_len] = '","attributes":[';
    assert token_uri[current_len + 1] = '{"trait_type":"Colorizations",';
    assert token_uri[current_len + 2] = '"value": "';

    let (colorizations: felt) = number_of_pixel_colorizations_total.read(rtwrk_id);
    let (colorizations_string: felt) = literal_from_number(colorizations);
    assert token_uri[current_len + 3] = colorizations_string;

    assert token_uri[current_len + 4] = '"},';

    assert token_uri[current_len + 5] = '{"trait_type":"Colorizers",';
    assert token_uri[current_len + 6] = '"value": "';

    let (colorizers_len, colorizers: felt*) = get_colorizers(rtwrk_id, 0);
    let (colorizers_string: felt) = literal_from_number(colorizers_len);
    assert token_uri[current_len + 7] = colorizers_string;

    assert token_uri[current_len + 8] = '"}],"image":"data:';

    assert token_uri[current_len + 9] = 'image/svg+xml,<?xml version=';
    assert token_uri[current_len + 10] = '\"1.0\" encoding=\"UTF-8\"?>';

    let (token_uri_len) = append_svg_from_pixel_grid(
        grid_size=grid_size,
        grid_array_len=grid_len,
        grid_array=grid,
        destination_len=current_len + 11,
        destination=token_uri,
    );

    assert token_uri[token_uri_len] = '"}';
    return (token_uri_len=token_uri_len + 1, token_uri=token_uri);
}
