%lang starknet
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import unsigned_div_rem, assert_le
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bool import TRUE
from starkware.cairo.common.uint256 import Uint256, uint256_eq

from pxls.utils.colors import Color
from pxls.PixelDrawer.storage import drawing_user_colorizations

const MAX_PIXEL_VALUE = 399  # grid of 400 pixels from 0 to 399
const MAX_COLOR_VALUE = 94  # palette of 95 colors from 0 to 94
const MAX_COLORIZATION_VALUE = MAX_PIXEL_VALUE * (MAX_COLOR_VALUE + 1) + MAX_COLOR_VALUE

const MAX_COLORIZATIONS_PER_TOKEN = 40

struct Colorization:
    member pixel_index : felt
    member color_index : felt
end

struct UserColorizations:
    member token_id : Uint256
    member colorizations_len : felt
    member colorizations : Colorization*
end

func pack_colorization{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(
    colorization : Colorization
) -> (pixel_colorization_packed : felt):
    with_attr error_message("Color index is out of bounds"):
        assert_le(colorization.color_index, MAX_COLOR_VALUE)
    end
    with_attr error_message("Pixel index is out of bounds"):
        assert_le(colorization.pixel_index, MAX_PIXEL_VALUE)
    end
    let colorization_packed = colorization.pixel_index * (MAX_COLOR_VALUE + 1) + colorization.color_index
    return (pixel_colorization_packed=colorization_packed)
end

func unpack_colorization{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(
    pixel_colorization_packed : felt
) -> (colorization : Colorization):
    let (pixel_index, color_index) = unsigned_div_rem(
        pixel_colorization_packed, MAX_COLOR_VALUE + 1
    )
    return (colorization=Colorization(pixel_index, color_index))
end

func pack_colorizations{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(
    colorizations_len : felt, colorizations : Colorization*, current_packed : felt
) -> (colorizations_packed : felt):
    alloc_locals
    if colorizations_len == 0:
        return (colorizations_packed=current_packed)
    end
    let (colorization_packed) = pack_colorization(colorizations[0])
    let new_packed = current_packed * (MAX_COLORIZATION_VALUE + 1) + colorization_packed
    return pack_colorizations(colorizations_len - 1, colorizations + Colorization.SIZE, new_packed)
end

func unpack_colorizations{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(
    colorizations_packed : felt
) -> (colorizations_len : felt, colorizations : Colorization*):
    alloc_locals

    let (colorizations : Colorization*) = alloc()
    # let (rest_packed, colorization_9_packed) = unsigned_div_rem(
    #     colorizations_packed, MAX_COLORIZATION_VALUE + 1
    # )
    # let (colorization_9 : Colorization) = unpack_colorization(colorization_9_packed)
    let (rest_packed, colorization_8_packed) = unsigned_div_rem(
        colorizations_packed, MAX_COLORIZATION_VALUE + 1
    )
    let (colorization_8 : Colorization) = unpack_colorization(colorization_8_packed)
    let (rest_packed, colorization_7_packed) = unsigned_div_rem(
        rest_packed, MAX_COLORIZATION_VALUE + 1
    )
    let (colorization_7 : Colorization) = unpack_colorization(colorization_7_packed)
    let (rest_packed, colorization_6_packed) = unsigned_div_rem(
        rest_packed, MAX_COLORIZATION_VALUE + 1
    )
    let (colorization_6 : Colorization) = unpack_colorization(colorization_6_packed)
    let (rest_packed, colorization_5_packed) = unsigned_div_rem(
        rest_packed, MAX_COLORIZATION_VALUE + 1
    )
    let (colorization_5 : Colorization) = unpack_colorization(colorization_5_packed)
    let (rest_packed, colorization_4_packed) = unsigned_div_rem(
        rest_packed, MAX_COLORIZATION_VALUE + 1
    )
    let (colorization_4 : Colorization) = unpack_colorization(colorization_4_packed)
    let (rest_packed, colorization_3_packed) = unsigned_div_rem(
        rest_packed, MAX_COLORIZATION_VALUE + 1
    )
    let (colorization_3 : Colorization) = unpack_colorization(colorization_3_packed)
    let (rest_packed, colorization_2_packed) = unsigned_div_rem(
        rest_packed, MAX_COLORIZATION_VALUE + 1
    )
    let (colorization_2 : Colorization) = unpack_colorization(colorization_2_packed)
    let (rest_packed, colorization_1_packed) = unsigned_div_rem(
        rest_packed, MAX_COLORIZATION_VALUE + 1
    )
    let (colorization_1 : Colorization) = unpack_colorization(colorization_1_packed)

    assert colorizations[0] = colorization_1
    assert colorizations[1] = colorization_2
    assert colorizations[2] = colorization_3
    assert colorizations[3] = colorization_4
    assert colorizations[4] = colorization_5
    assert colorizations[5] = colorization_6
    assert colorizations[6] = colorization_7
    assert colorizations[7] = colorization_8
    # assert colorizations[8] = colorization_9

    return (8, colorizations)
end

func pack_user_colorizations{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(
    user_colorizations : UserColorizations
) -> (user_colorizations_packed : felt):
    let (colorizations_packed) = pack_colorizations(
        user_colorizations.colorizations_len, user_colorizations.colorizations, 0
    )
    let user_colorizations_packed = colorizations_packed * (MAX_PIXEL_VALUE + 1) + user_colorizations.token_id.low
    return (user_colorizations_packed=user_colorizations_packed)
end

func unpack_user_colorizations{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(
    user_colorizations_packed
) -> (user_colorizations : UserColorizations):
    let (rest_packed, token_id_low) = unsigned_div_rem(
        user_colorizations_packed, MAX_PIXEL_VALUE + 1
    )
    let (colorizations_len : felt, colorizations : Colorization*) = unpack_colorizations(
        rest_packed
    )
    return (UserColorizations(Uint256(token_id_low, 0), colorizations_len, colorizations))
end

func get_all_drawing_user_colorizations{
    pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr
}(drawing_round : felt) -> (user_colorizations_len : felt, user_colorizations : UserColorizations*):
    let (user_colorizations : UserColorizations*) = alloc()
    return _get_all_drawing_user_colorizations(drawing_round, 0, user_colorizations)
end

func _get_all_drawing_user_colorizations{
    pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr
}(drawing_round : felt, user_colorizations_len : felt, user_colorizations : UserColorizations*) -> (
    user_colorizations_len : felt, user_colorizations : UserColorizations*
):
    let (storage_user_colorizations_packed) = drawing_user_colorizations.read(
        drawing_round, user_colorizations_len
    )
    if storage_user_colorizations_packed == 0:
        return (user_colorizations_len, user_colorizations)
    end
    let (unpacked_user_colorizations : UserColorizations) = unpack_user_colorizations(
        storage_user_colorizations_packed
    )
    assert user_colorizations[user_colorizations_len] = unpacked_user_colorizations
    return _get_all_drawing_user_colorizations(
        drawing_round, user_colorizations_len + 1, user_colorizations
    )
end

func save_drawing_user_colorizations{
    pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr
}(drawing_round : felt, user_colorizations : UserColorizations):
    alloc_locals
    # First find # of already saved slots
    let (
        stored_user_colorizations_len : felt, stored_user_colorizations : UserColorizations*
    ) = get_all_drawing_user_colorizations(drawing_round)
    let (colorizations_from_this_token_id) = count_colorizations_from_token_id(
        user_colorizations.token_id, stored_user_colorizations_len, stored_user_colorizations, 0
    )
    let colorizations_remaining = MAX_COLORIZATIONS_PER_TOKEN - colorizations_from_this_token_id
    with_attr error_message(
            "You have already done {colorizations_from_this_token_id} colorizations in this round, you cannot do {user_colorizations.colorizations_len} more"):
        assert_le(user_colorizations.colorizations_len, colorizations_remaining)
    end

    # Pack in a single felt
    let (packed_value_to_save) = pack_user_colorizations(user_colorizations)
    # Save in a new slot
    drawing_user_colorizations.write(
        drawing_round, stored_user_colorizations_len, packed_value_to_save
    )
    return ()
end

func count_colorizations_from_token_id{
    pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr
}(
    token_id : Uint256,
    stored_user_colorizations_len : felt,
    stored_user_colorizations : UserColorizations*,
    current_count : felt,
) -> (count : felt):
    if stored_user_colorizations_len == 0:
        return (current_count)
    end
    let user_colorization = stored_user_colorizations[0]
    let (is_from_this_token_id) = uint256_eq(token_id, user_colorization.token_id)
    if is_from_this_token_id == TRUE:
        return count_colorizations_from_token_id(
            token_id,
            stored_user_colorizations_len - 1,
            stored_user_colorizations + UserColorizations.SIZE,
            current_count + 1,
        )
    else:
        return count_colorizations_from_token_id(
            token_id,
            stored_user_colorizations_len - 1,
            stored_user_colorizations + UserColorizations.SIZE,
            current_count,
        )
    end
end
