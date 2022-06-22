%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.cairo_builtins import BitwiseBuiltin

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.memcpy import memcpy

from libs.utils import axis_coordinate_shortstring, felt_to_coordinates

func get_svg_start{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    svg_start_len : felt, svg_start : felt*
):
    let (svg_start : felt*) = alloc()
    assert svg_start[0] = 'data:image/svg+xml;utf8,<svg wi'
    assert svg_start[1] = 'dth="320" height="320" viewBox='
    assert svg_start[2] = '"0 0 320 320" xmlns="http://www'
    assert svg_start[3] = '.w3.org/2000/svg" shape-renderi'
    assert svg_start[4] = 'ng="crispEdges">'

    return (svg_start_len=5, svg_start=svg_start)
end

func get_svg_pixel{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    x, y, color
) -> (svg_pixel_end : felt, svg_pixel : felt*):
    alloc_locals
    let (local x_shortstring) = axis_coordinate_shortstring(x)
    let (local y_shortstring) = axis_coordinate_shortstring(y)
    let (svg_pixel : felt*) = alloc()
    assert svg_pixel[0] = '<rect width="10" height="10" x='
    assert svg_pixel[1] = '"'
    assert svg_pixel[2] = x_shortstring
    assert svg_pixel[3] = '" y="'
    assert svg_pixel[4] = y_shortstring
    assert svg_pixel[5] = '" fill="%23'
    assert svg_pixel[6] = color
    assert svg_pixel[7] = '" />'

    return (svg_pixel_end=8, svg_pixel=svg_pixel)
end

func get_svg_end{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    svg_end_len : felt, svg_end : felt*
):
    let (svg_end : felt*) = alloc()
    assert svg_end[0] = '</svg>'

    return (svg_end_len=1, svg_end=svg_end)
end

func add_svg_start{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    svg_array : felt*
) -> (svg_array_len):
    alloc_locals
    let (svg_start_len, svg_start : felt*) = get_svg_start()
    memcpy(dst=svg_array, src=svg_start, len=svg_start_len)
    return (svg_start_len)
end

func add_svg_pixel{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    svg_array_len, svg_array : felt*, x, y, color
) -> (svg_array_len):
    alloc_locals
    let (local svg_pixel_len, local svg_pixel : felt*) = get_svg_pixel(x=x, y=y, color=color)
    memcpy(dst=svg_array + svg_array_len, src=svg_pixel, len=svg_pixel_len)
    return (svg_array_len + svg_pixel_len)
end

func add_svg_pixels{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    svg_array_len, svg_array : felt*, pixels_len, pixels : felt*, current_pixel
) -> (svg_array_len):
    if pixels_len == 0:
        return (svg_array_len)
    end

    let (x, y) = felt_to_coordinates(current_pixel)
    let (svg_len) = add_svg_pixel(
        svg_array_len=svg_array_len, svg_array=svg_array, x=x, y=y, color=pixels[0]
    )
    return add_svg_pixels(
        svg_array_len=svg_len,
        svg_array=svg_array,
        pixels_len=pixels_len - 1,
        pixels=pixels + 1,
        current_pixel=current_pixel + 1,
    )
end

func add_svg_end{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    svg_array_len, svg_array : felt*
) -> (svg_array_len):
    alloc_locals
    let (local svg_end_len, local svg_end : felt*) = get_svg_end()
    memcpy(dst=svg_array + svg_array_len, src=svg_end, len=svg_end_len)
    return (svg_array_len + svg_end_len)
end

@view
func get_svg{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    pixels_len, pixels : felt*
) -> (svg_array_len : felt, svg_array : felt*):
    alloc_locals

    with_attr error_message("Pixel length must be 2. Got: {pixels_len}."):
        assert pixels_len = 2
    end

    let (local svg_array : felt*) = alloc()

    let (svg_len) = add_svg_start(svg_array)
    let (svg_len) = add_svg_pixels(
        svg_array_len=svg_len,
        svg_array=svg_array,
        pixels_len=pixels_len,
        pixels=pixels,
        current_pixel=0,
    )
    let (svg_len) = add_svg_end(svg_array_len=svg_len, svg_array=svg_array)

    return (svg_array_len=svg_len, svg_array=svg_array)
end
