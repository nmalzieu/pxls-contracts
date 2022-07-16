%lang starknet
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.registers import get_label_location

from contracts.pxls_metadata.svg import (
    svg_from_pixel_grid,
    svg_rect_from_pixel,
    pixel_coordinates_from_index,
    svg_rects_from_pixel_grid,
    svg_start_from_grid_size,
)
from caistring.str import Str, str_empty, literal_concat_known_length_dangerous
from libs.colors import Color

@view
func test_pixel_coordinates_from_index{
    syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*
}():
    # For a grid of 20 x 20 :
    # Pixel index starts at 0, ends at 399

    # 0 => (x=0, y=0)

    let (x, y) = pixel_coordinates_from_index(0, 20)
    assert 0 = x
    assert 0 = y

    # 19 => (x=19, y=0)

    let (x, y) = pixel_coordinates_from_index(19, 20)
    assert 19 = x
    assert 0 = y

    # 20 => (x=0, y=1)

    let (x, y) = pixel_coordinates_from_index(20, 20)
    assert 0 = x
    assert 1 = y

    # 29 => (x=9, y=1)

    let (x, y) = pixel_coordinates_from_index(29, 20)
    assert 9 = x
    assert 1 = y

    # 399 => (x=19, y=19)

    let (x, y) = pixel_coordinates_from_index(399, 20)
    assert 19 = x
    assert 19 = y

    return ()
end

@view
func test_svg_rect_from_pixel{syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*}():
    let (svg_rect_str : Str) = svg_rect_from_pixel(x=1, y=2, color=Color(255, 20, 100))

    # Result is <rect width="10" height="10" x="10" y="20" fill="COLOR" />
    # in the form of an array of length 4:

    # 1. <rect width="10" height="10" x=
    # 2. "
    # 3. 10" y="20" fill="rgb(
    # 4. 255,20,100)" />

    assert 3 = svg_rect_str.arr_len
    assert '<rect width="10" height="10" x=' = svg_rect_str.arr[0]
    assert '"10" y="20" fill="rgb(' = svg_rect_str.arr[1]
    assert '255,20,100)" />' = svg_rect_str.arr[2]

    return ()
end

@view
func test_svg_rects_from_pixel_grid{
    syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*
}():
    # Testing the method for a 2 x 2 grid = 4 rects

    let (grid_location) = get_label_location(grid_label)
    let grid_array = cast(grid_location, felt*)

    let (empty_str : Str) = str_empty()
    let (svg_rects_str : Str) = svg_rects_from_pixel_grid(
        grid_size=2, grid_array_len=4, grid_array=grid_array, pixel_index=0, current_str=empty_str
    )

    assert 12 = svg_rects_str.arr_len

    # Pixel 0, x = 0, y = 0, color index 0 => CCFFFF = 204,255,255

    assert '<rect width="10" height="10" x=' = svg_rects_str.arr[0]
    assert '"00" y="00" fill="rgb(' = svg_rects_str.arr[1]
    assert '204,255,255)" />' = svg_rects_str.arr[2]

    # Pixel 1, x = 10, y = 0, color index 3 => 33FFFF = 51,255,255

    assert '<rect width="10" height="10" x=' = svg_rects_str.arr[3]
    assert '"10" y="00" fill="rgb(' = svg_rects_str.arr[4]
    assert '51,255,255)" />' = svg_rects_str.arr[5]

    # Pixel 2, x = 0, y = 10, color index 12 => FF66FF = 255,102,255

    assert '<rect width="10" height="10" x=' = svg_rects_str.arr[6]
    assert '"00" y="10" fill="rgb(' = svg_rects_str.arr[7]
    assert '255,102,255)" />' = svg_rects_str.arr[8]

    # Pixel 3, x = 10, y = 10, color index 20 => FFFFCC = 255,255,204

    assert '<rect width="10" height="10" x=' = svg_rects_str.arr[9]
    assert '"10" y="10" fill="rgb(' = svg_rects_str.arr[10]
    assert '255,255,204)" />' = svg_rects_str.arr[11]

    return ()

    # Color 1 = index 0
    # Color 2 = index 3
    # Color 3 = index 12
    # Color 4 = index 20

    grid_label:
    dw 0
    dw 3
    dw 12
    dw 20
end

@view
func test_svg_start_from_grid_size{
    syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*
}():
    let (svg_start_str : Str) = svg_start_from_grid_size(20)
    # Result is <svg width="200" height="200" xmlns="http://www.w3.org/2000/svg">
    # in the form of an array of length 3:

    assert 3 = svg_start_str.arr_len
    assert '<svg width="200" height="20' = svg_start_str.arr[0]
    assert '0" xmlns="http://www.w3.org/200' = svg_start_str.arr[1]
    assert '0/svg">' = svg_start_str.arr[2]
    return ()
end

@view
func test_svg_from_pixel_grid{syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*}(
    ) -> (svg_str_len : felt, svg_str : felt*):
    # Testing the method for a 2 x 2 grid = 4 rects

    let (grid_location) = get_label_location(grid_label)
    let grid_array = cast(grid_location, felt*)

    let (svg_str : Str) = svg_from_pixel_grid(grid_size=2, grid_array_len=4, grid_array=grid_array)

    # 3 start, 4 rects of length 3, 1 end = 23
    assert 16 = svg_str.arr_len
    assert '<svg width="20" height="2' = svg_str.arr[0]
    assert '<rect width="10" height="10" x=' = svg_str.arr[6]
    assert '</svg>' = svg_str.arr[15]

    return (svg_str_len=svg_str.arr_len, svg_str=svg_str.arr)

    # Color 1 = index 7
    # Color 2 = index 14
    # Color 3 = index 11
    # Color 4 = index 9

    grid_label:
    dw 7
    dw 14
    dw 11
    dw 9
end
