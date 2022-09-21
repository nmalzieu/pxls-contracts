%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.bool import TRUE, FALSE

from pxls.RtwrkDrawer.colorization import (
    pack_pixel_colorization,
    unpack_pixel_colorization,
    pack_pixel_colorizations,
    unpack_pixel_colorizations,
    pack_colorization,
    unpack_colorization,
    PixelColorization,
    Colorization,
    save_rtwrk_colorization,
    get_all_rtwrk_colorizations,
)
from pxls.RtwrkDrawer.storage import max_colorizations_per_colorizer

from pxls.RtwrkDrawer.grid import get_grid

@view
func test_pack_single_pixel_colorization{
    syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}() {
    // Coloring pixel 400 in color 126
    let (packed_pixel_colorization) = pack_pixel_colorization(
        PixelColorization(pixel_index=399, color_index=94)
    );
    assert 37999 = packed_pixel_colorization;
    return ();
}

@view
func test_unpack_single_pixel_colorization{
    syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}() {
    // 37999 is the colorization returned from test_pack_single_colorization
    let (pixel_colorization: PixelColorization) = unpack_pixel_colorization(37999);
    assert 399 = pixel_colorization.pixel_index;
    assert 94 = pixel_colorization.color_index;
    return ();
}

@view
func test_pack_multiple_pixel_colorizations{
    syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}() {
    let (
        pixel_colorizations_len, pixel_colorizations: PixelColorization*
    ) = fixture_pixel_colorizations_1();

    let (packed_pixel_colorizations) = pack_pixel_colorizations(
        pixel_colorizations_len, pixel_colorizations, 0
    );

    assert 4347714592100644300337767135494028512 = packed_pixel_colorizations;
    return ();
}

@view
func test_unpack_multiple_pixel_colorizations{
    syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}() {
    alloc_locals;
    let (
        pixel_colorizations_len, pixel_colorizations: PixelColorization*
    ) = unpack_pixel_colorizations(4347714592100644300337767135494028512);

    assert 8 = pixel_colorizations_len;

    assert 399 = pixel_colorizations[0].pixel_index;
    assert 94 = pixel_colorizations[0].color_index;

    assert 128 = pixel_colorizations[1].pixel_index;
    assert 85 = pixel_colorizations[1].color_index;

    assert 36 = pixel_colorizations[2].pixel_index;
    assert 2 = pixel_colorizations[2].color_index;

    assert 360 = pixel_colorizations[3].pixel_index;
    assert 78 = pixel_colorizations[3].color_index;

    assert 220 = pixel_colorizations[4].pixel_index;
    assert 57 = pixel_colorizations[4].color_index;

    assert 48 = pixel_colorizations[5].pixel_index;
    assert 32 = pixel_colorizations[5].color_index;

    assert 178 = pixel_colorizations[6].pixel_index;
    assert 90 = pixel_colorizations[6].color_index;

    assert 300 = pixel_colorizations[7].pixel_index;
    assert 12 = pixel_colorizations[7].color_index;

    return ();
}

@view
func test_pack_colorization{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}() {
    let (colorization: Colorization) = fixture_colorization_1();
    let (packed_colorization) = pack_colorization(colorization);

    assert 1739085836840257720135106854197611404836 = packed_colorization;
    return ();
}

@view
func test_unpack_colorization{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}() {
    alloc_locals;
    let (colorization: Colorization) = unpack_colorization(
        1739085836840257720135106854197611404836
    );

    assert 0 = colorization.pxl_id.high;
    assert 36 = colorization.pxl_id.low;

    assert 8 = colorization.pixel_colorizations_len;

    assert 399 = colorization.pixel_colorizations[0].pixel_index;
    assert 94 = colorization.pixel_colorizations[0].color_index;

    assert 128 = colorization.pixel_colorizations[1].pixel_index;
    assert 85 = colorization.pixel_colorizations[1].color_index;

    assert 36 = colorization.pixel_colorizations[2].pixel_index;
    assert 2 = colorization.pixel_colorizations[2].color_index;

    assert 360 = colorization.pixel_colorizations[3].pixel_index;
    assert 78 = colorization.pixel_colorizations[3].color_index;

    assert 220 = colorization.pixel_colorizations[4].pixel_index;
    assert 57 = colorization.pixel_colorizations[4].color_index;

    assert 48 = colorization.pixel_colorizations[5].pixel_index;
    assert 32 = colorization.pixel_colorizations[5].color_index;

    assert 178 = colorization.pixel_colorizations[6].pixel_index;
    assert 90 = colorization.pixel_colorizations[6].color_index;

    assert 300 = colorization.pixel_colorizations[7].pixel_index;
    assert 12 = colorization.pixel_colorizations[7].color_index;

    return ();
}

@view
func test_save_rtwrk_colorization{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}(
    ) {
    alloc_locals;
    max_colorizations_per_colorizer.write(40);
    let (one_colorization: Colorization) = fixture_colorization_1();
    let (other_colorization: Colorization) = fixture_colorization_2();

    save_rtwrk_colorization(
        1,
        one_colorization.pxl_id,
        one_colorization.pixel_colorizations_len,
        one_colorization.pixel_colorizations,
    );
    save_rtwrk_colorization(
        1,
        other_colorization.pxl_id,
        other_colorization.pixel_colorizations_len,
        other_colorization.pixel_colorizations,
    );

    let (colorization_len: felt, colorizations: Colorization*) = get_all_rtwrk_colorizations(1, 0);

    assert 2 = colorization_len;

    // Verifying some data points

    assert 0 = colorizations[0].pxl_id.high;
    assert 36 = colorizations[0].pxl_id.low;

    assert 0 = colorizations[1].pxl_id.high;
    assert 321 = colorizations[1].pxl_id.low;

    assert 399 = colorizations[0].pixel_colorizations[0].pixel_index;
    assert 94 = colorizations[0].pixel_colorizations[0].color_index;

    assert 46 = colorizations[1].pixel_colorizations[0].pixel_index;
    assert 23 = colorizations[1].pixel_colorizations[0].color_index;

    let (grid_len: felt, grid: felt*) = get_grid(1, 400, 0);
    assert 1600 = grid_len;

    // We know pixel_index 35 is not colorized
    assert FALSE = grid[4 * 35];

    // We know pixel_index 399 is colorized with color 94 = 255, 255, 255 in colorization 1
    // pixel_index 46 is colorized with color 23 = 121, 134, 203 in colorization 2
    // pixel_index 48 is colorized twice - must have second color = color 20 = 26,35,126

    assert TRUE = grid[4 * 399];

    assert 255 = grid[4 * 399 + 1];
    assert 255 = grid[4 * 399 + 2];
    assert 255 = grid[4 * 399 + 3];

    assert TRUE = grid[4 * 46];

    assert 121 = grid[4 * 46 + 1];
    assert 134 = grid[4 * 46 + 2];
    assert 203 = grid[4 * 46 + 3];

    assert TRUE = grid[4 * 48];

    assert 26 = grid[4 * 48 + 1];
    assert 35 = grid[4 * 48 + 2];
    assert 126 = grid[4 * 48 + 3];  // Second value has overwritten the first value!

    return ();
}

@view
func test_save_rtwrk_colorizations_per_batch{
    syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}() {
    alloc_locals;
    max_colorizations_per_colorizer.write(40);
    let (pixel_colorizations: PixelColorization*) = alloc();

    assert pixel_colorizations[0] = PixelColorization(pixel_index=399, color_index=94);
    assert pixel_colorizations[1] = PixelColorization(pixel_index=128, color_index=85);
    assert pixel_colorizations[2] = PixelColorization(pixel_index=36, color_index=2);
    assert pixel_colorizations[3] = PixelColorization(pixel_index=360, color_index=78);
    assert pixel_colorizations[4] = PixelColorization(pixel_index=220, color_index=57);
    assert pixel_colorizations[5] = PixelColorization(pixel_index=48, color_index=32);
    assert pixel_colorizations[6] = PixelColorization(pixel_index=178, color_index=90);
    assert pixel_colorizations[7] = PixelColorization(pixel_index=300, color_index=12);
    assert pixel_colorizations[8] = PixelColorization(pixel_index=360, color_index=74);
    assert pixel_colorizations[9] = PixelColorization(pixel_index=123, color_index=57);
    assert pixel_colorizations[10] = PixelColorization(pixel_index=332, color_index=32);
    assert pixel_colorizations[11] = PixelColorization(pixel_index=22, color_index=90);
    assert pixel_colorizations[12] = PixelColorization(pixel_index=1, color_index=12);

    // Saving 13 pixel colorizations, more than 8, so 2 batches (1 of 8 and 1 of 5)
    save_rtwrk_colorization(1, Uint256(35, 0), 13, pixel_colorizations);

    let (colorizations_len: felt, colorizations: Colorization*) = get_all_rtwrk_colorizations(1, 0);

    assert 2 = colorizations_len;

    // Verifying some data points

    assert 0 = colorizations[0].pxl_id.high;
    assert 35 = colorizations[0].pxl_id.low;

    assert 399 = colorizations[0].pixel_colorizations[0].pixel_index;
    assert 94 = colorizations[0].pixel_colorizations[0].color_index;

    assert 0 = colorizations[1].pxl_id.high;
    assert 35 = colorizations[1].pxl_id.low;

    // Correponds to 9nth coloriztion
    assert 360 = colorizations[1].pixel_colorizations[0].pixel_index;
    assert 74 = colorizations[1].pixel_colorizations[0].color_index;

    return ();
}

func fixture_pixel_colorizations_1() -> (
    pixel_colorizations_len: felt, pixel_colorizations: PixelColorization*
) {
    let (pixel_colorizations: PixelColorization*) = alloc();

    assert pixel_colorizations[0] = PixelColorization(pixel_index=399, color_index=94);
    assert pixel_colorizations[1] = PixelColorization(pixel_index=128, color_index=85);
    assert pixel_colorizations[2] = PixelColorization(pixel_index=36, color_index=2);
    assert pixel_colorizations[3] = PixelColorization(pixel_index=360, color_index=78);
    assert pixel_colorizations[4] = PixelColorization(pixel_index=220, color_index=57);
    assert pixel_colorizations[5] = PixelColorization(pixel_index=48, color_index=32);
    assert pixel_colorizations[6] = PixelColorization(pixel_index=178, color_index=90);
    assert pixel_colorizations[7] = PixelColorization(pixel_index=300, color_index=12);
    return (8, pixel_colorizations);
}

func fixture_pixel_colorizations_2() -> (
    pixel_colorizations_len: felt, pixel_colorizations: PixelColorization*
) {
    let (pixel_colorizations: PixelColorization*) = alloc();

    assert pixel_colorizations[0] = PixelColorization(pixel_index=46, color_index=23);
    assert pixel_colorizations[1] = PixelColorization(pixel_index=123, color_index=35);
    assert pixel_colorizations[2] = PixelColorization(pixel_index=222, color_index=94);
    assert pixel_colorizations[3] = PixelColorization(pixel_index=2, color_index=3);
    assert pixel_colorizations[4] = PixelColorization(pixel_index=5, color_index=12);
    assert pixel_colorizations[5] = PixelColorization(pixel_index=48, color_index=20);
    assert pixel_colorizations[6] = PixelColorization(pixel_index=330, color_index=8);
    assert pixel_colorizations[7] = PixelColorization(pixel_index=228, color_index=87);
    return (8, pixel_colorizations);
}

func fixture_colorization_1() -> (colorization: Colorization) {
    let (
        pixel_colorizations_len, pixel_colorizations: PixelColorization*
    ) = fixture_pixel_colorizations_1();
    let pxl_id = Uint256(36, 0);
    let colorization = Colorization(pxl_id, pixel_colorizations_len, pixel_colorizations);
    return (colorization,);
}

func fixture_colorization_2() -> (colorization: Colorization) {
    let (
        pixel_colorizations_len, pixel_colorizations: PixelColorization*
    ) = fixture_pixel_colorizations_2();
    let pxl_id = Uint256(321, 0);
    let colorization = Colorization(pxl_id, pixel_colorizations_len, pixel_colorizations);
    return (colorization,);
}
