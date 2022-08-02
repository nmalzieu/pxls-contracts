%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.registers import get_label_location

from pxls.utils.colors import Color

func get_color_palette_name{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    palette_index : felt
) -> (palette_name : felt):
    let (palettes_location) = get_label_location(palettes_label)
    let palettes = cast(palettes_location, felt*)
    let palette_name = palettes[palette_index]
    return (palette_name=palette_name)

    palettes_label:
    dw 'cyan'
    dw 'blue'
    dw 'magenta'
    dw 'red'
    dw 'yellow'
    dw 'green'
end

func get_color{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    color_index : felt
) -> (color : Color):
    let (colors_location) = get_label_location(colors_label)
    let colors = cast(colors_location, Color*)
    return (color=colors[color_index])

    # Concatenating all colors from all palettes
    # in rgb form in that order:

    # cyan = ["CCFFFF", "99FFFF", "66FFFF", "33FFFF", "00FFFF"]
    # blue = ["CCCCFF", "9999FF", "6666FF", "3333FF", "0000FF"]
    # magenta = ["FFCCFF", "FF99FF", "FF66FF", "FF33FF", "FF00FF"]
    # red = ["FFCCCC", "FF9999", "FF6666", "FF3333", "FF0000"]
    # yellow = ["FFFFCC", "FFFF99", "FFFF66", "FFFF33", "FFFF00"]
    # green = ["CCFFCC", "99FF99", "66FF66", "33FF33", "00FF00"]

    colors_label:
    dw 204
    dw 255
    dw 255
    dw 153
    dw 255
    dw 255
    dw 102
    dw 255
    dw 255
    dw 51
    dw 255
    dw 255
    dw 0
    dw 255
    dw 255
    dw 204
    dw 204
    dw 255
    dw 153
    dw 153
    dw 255
    dw 102
    dw 102
    dw 255
    dw 51
    dw 51
    dw 255
    dw 0
    dw 0
    dw 255
    dw 255
    dw 204
    dw 255
    dw 255
    dw 153
    dw 255
    dw 255
    dw 102
    dw 255
    dw 255
    dw 51
    dw 255
    dw 255
    dw 0
    dw 255
    dw 255
    dw 204
    dw 204
    dw 255
    dw 153
    dw 153
    dw 255
    dw 102
    dw 102
    dw 255
    dw 51
    dw 51
    dw 255
    dw 0
    dw 0
    dw 255
    dw 255
    dw 204
    dw 255
    dw 255
    dw 153
    dw 255
    dw 255
    dw 102
    dw 255
    dw 255
    dw 51
    dw 255
    dw 255
    dw 0
    dw 204
    dw 255
    dw 204
    dw 153
    dw 255
    dw 153
    dw 102
    dw 255
    dw 102
    dw 51
    dw 255
    dw 51
    dw 0
    dw 255
    dw 0
end
