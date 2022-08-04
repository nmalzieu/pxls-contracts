%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.bool import TRUE, FALSE

from pxls.PixelDrawer.colorization import (
    pack_colorization,
    unpack_colorization,
    pack_colorizations,
    unpack_colorizations,
    pack_user_colorizations,
    unpack_user_colorizations,
    Colorization,
    UserColorizations,
    save_drawing_user_colorizations,
    get_all_drawing_user_colorizations,
)

from pxls.PixelDrawer.grid import get_grid

@view
func test_pack_single_colorization{
    syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*
}():
    # Coloring pixel 400 in color 126
    let (packed_colorization) = pack_colorization(Colorization(pixel_index=399, color_index=94))
    assert 37999 = packed_colorization
    return ()
end

@view
func test_unpack_single_colorization{
    syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*
}():
    # 37999 is the colorization returned from test_pack_single_colorization
    let (colorization : Colorization) = unpack_colorization(37999)
    assert 399 = colorization.pixel_index
    assert 94 = colorization.color_index
    return ()
end

func fixture_colorizations_1() -> (colorizations_len : felt, colorizations : Colorization*):
    let (colorizations : Colorization*) = alloc()

    assert colorizations[0] = Colorization(pixel_index=399, color_index=94)
    assert colorizations[1] = Colorization(pixel_index=128, color_index=85)
    assert colorizations[2] = Colorization(pixel_index=36, color_index=2)
    assert colorizations[3] = Colorization(pixel_index=360, color_index=78)
    assert colorizations[4] = Colorization(pixel_index=220, color_index=57)
    assert colorizations[5] = Colorization(pixel_index=48, color_index=32)
    assert colorizations[6] = Colorization(pixel_index=178, color_index=90)
    assert colorizations[7] = Colorization(pixel_index=300, color_index=12)
    return (8, colorizations)
end

func fixture_colorizations_2() -> (colorizations_len : felt, colorizations : Colorization*):
    let (colorizations : Colorization*) = alloc()

    assert colorizations[0] = Colorization(pixel_index=46, color_index=23)
    assert colorizations[1] = Colorization(pixel_index=123, color_index=35)
    assert colorizations[2] = Colorization(pixel_index=222, color_index=94)
    assert colorizations[3] = Colorization(pixel_index=2, color_index=3)
    assert colorizations[4] = Colorization(pixel_index=5, color_index=12)
    assert colorizations[5] = Colorization(pixel_index=48, color_index=20)
    assert colorizations[6] = Colorization(pixel_index=330, color_index=8)
    assert colorizations[7] = Colorization(pixel_index=228, color_index=87)
    return (8, colorizations)
end

func fixture_user_colorizations_1() -> (user_colorizations : UserColorizations):
    let (colorizations_len, colorizations : Colorization*) = fixture_colorizations_1()
    let token_id = Uint256(36, 0)
    let user_colorizations = UserColorizations(token_id, colorizations_len, colorizations)
    return (user_colorizations)
end

func fixture_user_colorizations_2() -> (user_colorizations : UserColorizations):
    let (colorizations_len, colorizations : Colorization*) = fixture_colorizations_2()
    let token_id = Uint256(321, 0)
    let user_colorizations = UserColorizations(token_id, colorizations_len, colorizations)
    return (user_colorizations)
end

@view
func test_pack_multiple_colorizations{
    syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*
}():
    let (colorizations_len, colorizations : Colorization*) = fixture_colorizations_1()

    let (packed_colorizations) = pack_colorizations(colorizations_len, colorizations, 0)

    assert 4347714592100644300337767135494028512 = packed_colorizations
    return ()
end

@view
func test_unpack_multiple_colorizations{
    syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*
}():
    alloc_locals
    let (colorizations_len, colorizations : Colorization*) = unpack_colorizations(
        4347714592100644300337767135494028512
    )

    assert 8 = colorizations_len

    assert 399 = colorizations[0].pixel_index
    assert 94 = colorizations[0].color_index

    assert 128 = colorizations[1].pixel_index
    assert 85 = colorizations[1].color_index

    assert 36 = colorizations[2].pixel_index
    assert 2 = colorizations[2].color_index

    assert 360 = colorizations[3].pixel_index
    assert 78 = colorizations[3].color_index

    assert 220 = colorizations[4].pixel_index
    assert 57 = colorizations[4].color_index

    assert 48 = colorizations[5].pixel_index
    assert 32 = colorizations[5].color_index

    assert 178 = colorizations[6].pixel_index
    assert 90 = colorizations[6].color_index

    assert 300 = colorizations[7].pixel_index
    assert 12 = colorizations[7].color_index

    # assert 76 = colorizations[8].pixel_index
    # assert 76 = colorizations[8].color_index

    return ()
end

@view
func test_pack_user_colorizations{
    syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*
}():
    let (user_colorizations : UserColorizations) = fixture_user_colorizations_1()
    let (packed_user_colorizations) = pack_user_colorizations(user_colorizations)

    assert 1739085836840257720135106854197611404836 = packed_user_colorizations
    return ()
end

@view
func test_unpack_user_colorizations{
    syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*
}():
    alloc_locals
    let (user_colorizations : UserColorizations) = unpack_user_colorizations(
        1739085836840257720135106854197611404836
    )

    assert 0 = user_colorizations.token_id.high
    assert 36 = user_colorizations.token_id.low

    assert 8 = user_colorizations.colorizations_len

    assert 399 = user_colorizations.colorizations[0].pixel_index
    assert 94 = user_colorizations.colorizations[0].color_index

    assert 128 = user_colorizations.colorizations[1].pixel_index
    assert 85 = user_colorizations.colorizations[1].color_index

    assert 36 = user_colorizations.colorizations[2].pixel_index
    assert 2 = user_colorizations.colorizations[2].color_index

    assert 360 = user_colorizations.colorizations[3].pixel_index
    assert 78 = user_colorizations.colorizations[3].color_index

    assert 220 = user_colorizations.colorizations[4].pixel_index
    assert 57 = user_colorizations.colorizations[4].color_index

    assert 48 = user_colorizations.colorizations[5].pixel_index
    assert 32 = user_colorizations.colorizations[5].color_index

    assert 178 = user_colorizations.colorizations[6].pixel_index
    assert 90 = user_colorizations.colorizations[6].color_index

    assert 300 = user_colorizations.colorizations[7].pixel_index
    assert 12 = user_colorizations.colorizations[7].color_index

    # assert 76 = colorizations[8].pixel_index
    # assert 76 = colorizations[8].color_index

    return ()
end

@view
func test_save_drawing_user_colorizations{
    syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*
}():
    alloc_locals
    let (one_user_colorizations : UserColorizations) = fixture_user_colorizations_1()
    let (other_user_colorizations : UserColorizations) = fixture_user_colorizations_2()

    save_drawing_user_colorizations(1, one_user_colorizations)
    save_drawing_user_colorizations(1, other_user_colorizations)

    let (
        user_colorizations_len : felt, user_colorizations : UserColorizations*
    ) = get_all_drawing_user_colorizations(1)

    assert 2 = user_colorizations_len

    # Verifying some data points

    assert 0 = user_colorizations[0].token_id.high
    assert 36 = user_colorizations[0].token_id.low

    assert 0 = user_colorizations[1].token_id.high
    assert 321 = user_colorizations[1].token_id.low

    assert 399 = user_colorizations[0].colorizations[0].pixel_index
    assert 94 = user_colorizations[0].colorizations[0].color_index

    assert 46 = user_colorizations[1].colorizations[0].pixel_index
    assert 23 = user_colorizations[1].colorizations[0].color_index

    let (grid_len : felt, grid : felt*) = get_grid(1, 400)
    assert 1600 = grid_len

    # We know pixel_index 35 is not colorized
    assert FALSE = grid[4 * 35]

    # We know pixel_index 399 is colorized with color 94 = 255, 255, 255 in colorization 1
    # pixel_index 46 is colorized with color 23 = 121, 134, 203 in colorization 2
    # pixel_index 48 is colorized twice - must have second color = color 20 = 26,35,126

    assert TRUE = grid[4 * 399]

    assert 255 = grid[4 * 399 + 1]
    assert 255 = grid[4 * 399 + 2]
    assert 255 = grid[4 * 399 + 3]

    assert TRUE = grid[4 * 46]

    assert 121 = grid[4 * 46 + 1]
    assert 134 = grid[4 * 46 + 2]
    assert 203 = grid[4 * 46 + 3]

    assert TRUE = grid[4 * 48]

    assert 26 = grid[4 * 48 + 1]
    assert 35 = grid[4 * 48 + 2]
    assert 126 = grid[4 * 48 + 3]  # Second value has overwritten the first value!

    return ()
end
