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
from caistring.str import Str
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
    # in the form of an array of length 12:

    # 1. <rect width="10" height="10" x=
    # 2. "
    # 3. 10
    # 4. " y="
    # 5. 20
    # 6. " fill="rgb(
    # 7. 255
    # 8. ,
    # 9. 20
    # 10. ,
    # 11. 100
    # 12. )" />

    assert 12 = svg_rect_str.arr_len
    assert '<rect width="10" height="10" x=' = svg_rect_str.arr[0]
    assert '"' = svg_rect_str.arr[1]
    assert '10' = svg_rect_str.arr[2]
    assert '" y="' = svg_rect_str.arr[3]
    assert '20' = svg_rect_str.arr[4]
    assert '" fill="rgb(' = svg_rect_str.arr[5]
    assert '255' = svg_rect_str.arr[6]
    assert ',' = svg_rect_str.arr[7]
    assert '20' = svg_rect_str.arr[8]
    assert ',' = svg_rect_str.arr[9]
    assert '100' = svg_rect_str.arr[10]
    assert ')" />' = svg_rect_str.arr[11]
    return ()
end

@view
func test_svg_rects_from_pixel_grid{
    syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*
}():
    # Testing the method for a 2 x 2 grid = 4 rects

    let (grid_location) = get_label_location(grid_label)
    let grid_array = cast(grid_location, felt*)

    let (svg_rects_str : Str) = svg_rects_from_pixel_grid(
        grid_size=2, grid_array_len=4, grid_array=grid_array, pixel_index=0
    )

    assert 48 = svg_rects_str.arr_len

    # Pixel 0, x = 0, y = 0, color index 0 => CCFFFF = 204,255,255

    assert '<rect width="10" height="10" x=' = svg_rects_str.arr[0]
    assert '"' = svg_rects_str.arr[1]
    assert '0' = svg_rects_str.arr[2]
    assert '" y="' = svg_rects_str.arr[3]
    assert '0' = svg_rects_str.arr[4]
    assert '" fill="rgb(' = svg_rects_str.arr[5]
    assert '204' = svg_rects_str.arr[6]
    assert ',' = svg_rects_str.arr[7]
    assert '255' = svg_rects_str.arr[8]
    assert ',' = svg_rects_str.arr[9]
    assert '255' = svg_rects_str.arr[10]
    assert ')" />' = svg_rects_str.arr[11]

    # Pixel 1, x = 10, y = 0, color index 3 => 33FFFF = 51,255,255

    assert '<rect width="10" height="10" x=' = svg_rects_str.arr[12]
    assert '"' = svg_rects_str.arr[13]
    assert '10' = svg_rects_str.arr[14]
    assert '" y="' = svg_rects_str.arr[15]
    assert '0' = svg_rects_str.arr[16]
    assert '" fill="rgb(' = svg_rects_str.arr[17]
    assert '51' = svg_rects_str.arr[18]
    assert ',' = svg_rects_str.arr[19]
    assert '255' = svg_rects_str.arr[20]
    assert ',' = svg_rects_str.arr[21]
    assert '255' = svg_rects_str.arr[22]
    assert ')" />' = svg_rects_str.arr[23]

    # Pixel 2, x = 0, y = 10, color index 12 => FF66FF = 255,102,255

    assert '<rect width="10" height="10" x=' = svg_rects_str.arr[24]
    assert '"' = svg_rects_str.arr[25]
    assert '0' = svg_rects_str.arr[26]
    assert '" y="' = svg_rects_str.arr[27]
    assert '10' = svg_rects_str.arr[28]
    assert '" fill="rgb(' = svg_rects_str.arr[29]
    assert '255' = svg_rects_str.arr[30]
    assert ',' = svg_rects_str.arr[31]
    assert '102' = svg_rects_str.arr[32]
    assert ',' = svg_rects_str.arr[33]
    assert '255' = svg_rects_str.arr[34]
    assert ')" />' = svg_rects_str.arr[35]

    # Pixel 3, x = 10, y = 10, color index 20 => FFFFCC = 255,255,204

    assert '<rect width="10" height="10" x=' = svg_rects_str.arr[36]
    assert '"' = svg_rects_str.arr[37]
    assert '10' = svg_rects_str.arr[38]
    assert '" y="' = svg_rects_str.arr[39]
    assert '10' = svg_rects_str.arr[40]
    assert '" fill="rgb(' = svg_rects_str.arr[41]
    assert '255' = svg_rects_str.arr[42]
    assert ',' = svg_rects_str.arr[43]
    assert '255' = svg_rects_str.arr[44]
    assert ',' = svg_rects_str.arr[45]
    assert '204' = svg_rects_str.arr[46]
    assert ')" />' = svg_rects_str.arr[47]

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
    # in the form of an array of length 6:

    # 1. <svg width="
    # 2. 200
    # 3. " height="
    # 4. 200
    # 5. " xmlns="http://www.w3.org/2000
    # 6. /svg">

    assert 6 = svg_start_str.arr_len
    assert '<svg width="' = svg_start_str.arr[0]
    assert '200' = svg_start_str.arr[1]
    assert '" height="' = svg_start_str.arr[2]
    assert '200' = svg_start_str.arr[3]
    assert '" xmlns="http://www.w3.org/2000' = svg_start_str.arr[4]
    assert '/svg">' = svg_start_str.arr[5]
    return ()
end

@view
func test_svg_from_pixel_grid{syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*}(
    ) -> (svg_str_len : felt, svg_str : felt*):
    # Testing the method for a 2 x 2 grid = 4 rects

    let (grid_location) = get_label_location(grid_label)
    let grid_array = cast(grid_location, felt*)

    # 12 x 12 works, 20 x 20 raises OUT_OF_RESOURCES

    let (svg_str : Str) = svg_from_pixel_grid(grid_size=2, grid_array_len=4, grid_array=grid_array)

    # 6 start, 400 rects of length 12, 1 end = 4807
    # assert 4807 = svg_str.arr_len
    # assert '<svg width="' = svg_str.arr[0]
    # assert '<rect width="10" height="10" x=' = svg_str.arr[6]
    # assert '</svg>' = svg_str.arr[4806]

    # 6 start, 4 rects of length 12, 1 end = 55
    assert 55 = svg_str.arr_len
    assert '<svg width="' = svg_str.arr[0]
    assert '<rect width="10" height="10" x=' = svg_str.arr[6]
    assert '</svg>' = svg_str.arr[54]

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
    dw 22
    dw 8
    dw 24
    dw 8
    dw 13
    dw 8
    dw 13
    dw 1
    dw 5
    dw 22
    dw 10
    dw 0
    dw 14
    dw 14
    dw 8
    dw 24
    dw 22
    dw 4
    dw 3
    dw 5
    dw 7
    dw 0
    dw 11
    dw 22
    dw 20
    dw 12
    dw 13
    dw 24
    dw 21
    dw 24
    dw 4
    dw 12
    dw 22
    dw 1
    dw 14
    dw 4
    dw 0
    dw 3
    dw 8
    dw 2
    dw 5
    dw 2
    dw 2
    dw 9
    dw 21
    dw 7
    dw 13
    dw 8
    dw 11
    dw 12
    dw 23
    dw 14
    dw 0
    dw 2
    dw 4
    dw 6
    dw 4
    dw 9
    dw 1
    dw 7
    dw 24
    dw 22
    dw 5
    dw 12
    dw 1
    dw 4
    dw 22
    dw 8
    dw 22
    dw 5
    dw 10
    dw 8
    dw 2
    dw 7
    dw 4
    dw 6
    dw 13
    dw 9
    dw 22
    dw 11
    dw 9
    dw 20
    dw 0
    dw 24
    dw 5
    dw 8
    dw 9
    dw 13
    dw 8
    dw 8
    dw 11
    dw 0
    dw 20
    dw 6
    dw 7
    dw 14
    dw 11
    dw 9
    dw 10
    dw 22
    dw 22
    dw 2
    dw 5
    dw 2
    dw 3
    dw 9
    dw 4
    dw 1
    dw 21
    dw 14
    dw 6
    dw 13
    dw 5
    dw 7
    dw 13
    dw 22
    dw 13
    dw 5
    dw 0
    dw 7
    dw 4
    dw 3
    dw 24
    dw 12
    dw 1
    dw 13
    dw 8
    dw 6
    dw 11
    dw 5
    dw 22
    dw 8
    dw 10
    dw 24
    dw 22
    dw 0
    dw 14
    dw 4
    dw 4
    dw 12
    dw 2
    dw 2
    dw 20
    dw 7
    dw 7
    dw 3
    dw 9
    dw 3
    dw 0
    dw 13
    dw 3
    dw 6
    dw 11
    dw 3
    dw 20
    dw 11
    dw 14
    dw 3
    dw 4
    dw 7
    dw 4
    dw 12
    dw 21
    dw 11
    dw 14
    dw 20
    dw 23
    dw 5
    dw 14
    dw 11
    dw 8
    dw 0
    dw 4
    dw 24
    dw 14
    dw 9
    dw 7
    dw 5
    dw 0
    dw 3
    dw 22
    dw 10
    dw 8
    dw 24
    dw 5
    dw 24
    dw 24
    dw 5
    dw 10
    dw 0
    dw 22
    dw 2
    dw 0
    dw 0
    dw 1
    dw 20
    dw 2
    dw 6
    dw 23
    dw 4
    dw 23
    dw 4
    dw 9
    dw 24
    dw 22
    dw 8
    dw 14
    dw 7
    dw 4
    dw 24
    dw 6
    dw 13
    dw 22
    dw 13
    dw 7
    dw 14
    dw 20
    dw 0
    dw 10
    dw 1
    dw 8
    dw 9
    dw 21
    dw 4
    dw 6
    dw 5
    dw 4
    dw 0
    dw 5
    dw 23
    dw 9
    dw 24
    dw 0
    dw 12
    dw 10
    dw 12
    dw 6
    dw 22
    dw 13
    dw 11
    dw 2
    dw 12
    dw 3
    dw 24
    dw 21
    dw 7
    dw 2
    dw 21
    dw 21
    dw 2
    dw 23
    dw 7
    dw 0
    dw 6
    dw 5
    dw 13
    dw 6
    dw 21
    dw 2
    dw 9
    dw 11
    dw 2
    dw 9
    dw 8
    dw 24
    dw 0
    dw 11
    dw 13
    dw 13
    dw 24
    dw 12
    dw 10
    dw 8
    dw 5
    dw 24
    dw 9
    dw 6
    dw 4
    dw 6
    dw 1
    dw 4
    dw 23
    dw 14
    dw 21
    dw 8
    dw 8
    dw 3
    dw 2
    dw 2
    dw 22
    dw 3
    dw 10
    dw 23
    dw 9
    dw 1
    dw 11
    dw 10
    dw 6
    dw 6
    dw 0
    dw 5
    dw 4
    dw 10
    dw 4
    dw 14
    dw 13
    dw 4
    dw 3
    dw 7
    dw 10
    dw 2
    dw 12
    dw 20
    dw 22
    dw 14
    dw 12
    dw 11
    dw 6
    dw 1
    dw 1
    dw 13
    dw 7
    dw 11
    dw 8
    dw 1
    dw 7
    dw 22
    dw 9
    dw 2
    dw 5
    dw 24
    dw 10
    dw 7
    dw 22
    dw 2
    dw 11
    dw 3
    dw 20
    dw 24
    dw 12
    dw 13
    dw 13
    dw 10
    dw 10
    dw 10
    dw 10
    dw 3
    dw 14
    dw 1
    dw 24
    dw 24
    dw 4
    dw 4
    dw 22
    dw 6
    dw 10
    dw 2
    dw 20
    dw 24
    dw 2
    dw 10
    dw 3
    dw 0
    dw 22
    dw 11
    dw 10
    dw 20
    dw 23
    dw 23
    dw 8
    dw 10
    dw 5
    dw 14
    dw 1
    dw 12
    dw 13
    dw 11
    dw 10
    dw 13
    dw 6
    dw 11
    dw 10
    dw 21
    dw 10
    dw 1
    dw 11
    dw 24
    dw 8
    dw 11
    dw 23
    dw 1
    dw 20
    dw 3
    dw 12
    dw 14
    dw 10
end
