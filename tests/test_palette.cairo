%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from pxls.PixelDrawer.palette import get_palette_color
from pxls.utils.colors import Color

@view
func test_get_palette_color{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}() {
    let (color: Color) = get_palette_color(2);
    assert 244 = color.red;
    assert 67 = color.green;
    assert 54 = color.blue;

    let (color: Color) = get_palette_color(94);
    assert 255 = color.red;
    assert 255 = color.green;
    assert 255 = color.blue;

    %{ expect_revert(error_message="Only 95 colors in this palette") %}

    let (color: Color) = get_palette_color(95);
    return ();
}
