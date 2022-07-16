%lang starknet
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.alloc import alloc

from contracts.pxls_metadata.pxls_colors import get_color_palette_name, get_color

@view
func test_get_color_palette_name{syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*}(
    ):
    let (cyan) = get_color_palette_name(0)
    assert 'cyan' = cyan
    return ()
end

@view
func test_get_color{syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*}():
    # cyan = ["CCFFFF", "99FFFF", "66FFFF", "33FFFF", "00FFFF"]
    # blue = ["CCCCFF", "9999FF", "6666FF", "3333FF", "0000FF"]
    # magenta = ["FFCCFF", "FF99FF", "FF66FF", "FF33FF", "FF00FF"]
    # red = ["FFCCCC", "FF9999", "FF6666", "FF3333", "FF0000"]
    # yellow = ["FFFFCC", "FFFF99", "FFFF66", "FFFF33", "FFFF00"]
    # green = ["CCFFCC", "99FF99", "66FF66", "33FF33", "00FF00"]

    # Color 13 is supposed to be FF66FF = 255,102,255
    let (FF66FF) = get_color(12)
    assert 255 = FF66FF.red
    assert 102 = FF66FF.green
    assert 255 = FF66FF.blue

    return ()
end
