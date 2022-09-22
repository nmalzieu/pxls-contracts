%lang starknet
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import unsigned_div_rem, assert_le
from starkware.cairo.common.math_cmp import is_le
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.uint256 import Uint256, uint256_eq
from starkware.cairo.common.default_dict import default_dict_new, default_dict_finalize
from starkware.cairo.common.dict_access import DictAccess
from starkware.cairo.common.dict import dict_write, dict_read

from pxls.utils.colors import Color
from pxls.RtwrkDrawer.storage import (
    rtwrk_colorizations,
    max_pixel_colorizations_per_colorizer,
    number_of_pixel_colorizations_per_colorizer,
    number_of_pixel_colorizations_total,
    rtwrk_colorization_index,
)

const MAX_PIXEL_VALUE = 399;  // grid of 400 pixels from 0 to 399
const MAX_COLOR_VALUE = 94;  // palette of 95 colors from 0 to 94
const MAX_COLORIZATION_VALUE = MAX_PIXEL_VALUE * (MAX_COLOR_VALUE + 1) + MAX_COLOR_VALUE;
const MAX_COLORIZATIONS_PER_FELT = 8;  // There is space to store more, but we can't unpack due to div_rem bounds
const MAX_TOTAL_COLORIZATIONS = 2000;  // For performance limit to reconstitute grid

struct PixelColorization {
    pixel_index: felt,
    color_index: felt,
}

struct Colorization {
    pxl_id: Uint256,
    pixel_colorizations_len: felt,
    pixel_colorizations: PixelColorization*,
}

func pack_pixel_colorization{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    pixel_colorization: PixelColorization
) -> (pixel_colorization_packed: felt) {
    with_attr error_message("Color index is out of bounds") {
        assert_le(pixel_colorization.color_index, MAX_COLOR_VALUE);
    }
    with_attr error_message("Pixel index is out of bounds") {
        assert_le(pixel_colorization.pixel_index, MAX_PIXEL_VALUE);
    }
    let pixel_colorization_packed = pixel_colorization.pixel_index * (MAX_COLOR_VALUE + 1) + pixel_colorization.color_index;
    return (pixel_colorization_packed=pixel_colorization_packed);
}

func unpack_pixel_colorization{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    pixel_colorization_packed: felt
) -> (pixel_colorization: PixelColorization) {
    let (pixel_index, color_index) = unsigned_div_rem(
        pixel_colorization_packed, MAX_COLOR_VALUE + 1
    );
    return (pixel_colorization=PixelColorization(pixel_index, color_index));
}

func pack_pixel_colorizations{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    pixel_colorizations_len: felt, pixel_colorizations: PixelColorization*, current_packed: felt
) -> (pixel_colorizations_packed: felt) {
    alloc_locals;
    if (pixel_colorizations_len == 0) {
        return (pixel_colorizations_packed=current_packed);
    }
    let (pixel_colorization_packed) = pack_pixel_colorization(pixel_colorizations[0]);
    let new_packed = current_packed * (MAX_COLORIZATION_VALUE + 1) + pixel_colorization_packed;
    return pack_pixel_colorizations(
        pixel_colorizations_len - 1, pixel_colorizations + PixelColorization.SIZE, new_packed
    );
}

func unpack_pixel_colorizations{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    pixel_colorizations_packed: felt
) -> (pixel_colorizations_len: felt, pixel_colorizations: PixelColorization*) {
    alloc_locals;

    let (pixel_colorizations: PixelColorization*) = alloc();
    let (pixel_colorizations_len) = _unpack_pixel_colorizations(
        pixel_colorizations_packed, 0, pixel_colorizations
    );

    return reverse_pixel_colorizations(pixel_colorizations_len, pixel_colorizations);
}

func _unpack_pixel_colorizations{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    pixel_colorizations_packed: felt,
    pixel_colorizations_len: felt,
    pixel_colorizations: PixelColorization*,
) -> (pixel_colorizations_len: felt) {
    let (rest_packed, pixel_colorization_packed) = unsigned_div_rem(
        pixel_colorizations_packed, MAX_COLORIZATION_VALUE + 1
    );

    let (pixel_colorization: PixelColorization) = unpack_pixel_colorization(
        pixel_colorization_packed
    );
    assert pixel_colorizations[pixel_colorizations_len] = pixel_colorization;

    if (rest_packed == 0) {
        return (pixel_colorizations_len + 1,);
    }

    return _unpack_pixel_colorizations(
        rest_packed, pixel_colorizations_len + 1, pixel_colorizations
    );
}

func pack_colorization{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    colorization: Colorization
) -> (colorization_packed: felt) {
    let (pixel_colorizations_packed) = pack_pixel_colorizations(
        colorization.pixel_colorizations_len, colorization.pixel_colorizations, 0
    );
    let colorization_packed = pixel_colorizations_packed * (MAX_PIXEL_VALUE + 1) + colorization.pxl_id.low;
    return (colorization_packed=colorization_packed);
}

func unpack_colorization{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    colorization_packed
) -> (colorization: Colorization) {
    alloc_locals;
    let (rest_packed, pxl_id_low) = unsigned_div_rem(colorization_packed, MAX_PIXEL_VALUE + 1);
    let (
        pixel_colorizations_len: felt, pixel_colorizations: PixelColorization*
    ) = unpack_pixel_colorizations(rest_packed);
    return (Colorization(Uint256(pxl_id_low, 0), pixel_colorizations_len, pixel_colorizations),);
}

func get_all_rtwrk_colorizations{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    rtwrk_id: felt, rtwrk_step: felt
) -> (colorizations_len: felt, colorizations: Colorization*) {
    let (colorizations: Colorization*) = alloc();
    return _get_all_rtwrk_colorizations(rtwrk_id, 0, colorizations, rtwrk_step);
}

func _get_all_rtwrk_colorizations{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    rtwrk_id: felt, colorizations_len: felt, colorizations: Colorization*, rtwrk_step: felt
) -> (colorizations_len: felt, colorizations: Colorization*) {
    alloc_locals;
    let (storage_colorization_packed) = rtwrk_colorizations.read(rtwrk_id, colorizations_len);
    // We reached the end of the colorizations array
    if (storage_colorization_packed == 0) {
        return (colorizations_len, colorizations);
    }
    // If we provided a step, let's stop at this step
    if (colorizations_len != 0) {
        if (colorizations_len == rtwrk_step) {
            return (colorizations_len, colorizations);
        }
    }
    let (unpacked_colorization: Colorization) = unpack_colorization(storage_colorization_packed);
    assert colorizations[colorizations_len] = unpacked_colorization;
    return _get_all_rtwrk_colorizations(rtwrk_id, colorizations_len + 1, colorizations, rtwrk_step);
}

func save_rtwrk_colorization{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    rtwrk_id: felt,
    pxl_id: Uint256,
    pixel_colorizations_len: felt,
    pixel_colorizations: PixelColorization*,
) {
    alloc_locals;
    // First find # of already saved slots
    let (stored_colorization_len: felt) = rtwrk_colorization_index.read(rtwrk_id);
    // Then # of colorizations done by this token
    let (colorizations_from_this_pxl_id) = number_of_pixel_colorizations_per_colorizer.read(
        rtwrk_id, pxl_id
    );
    // Then total # of colorizations for all tokens
    let (total_colorizations_count) = number_of_pixel_colorizations_total.read(rtwrk_id);
    // Then max colorizations allowed per token
    let (max_token_colorizations) = max_pixel_colorizations_per_colorizer.read();
    let colorizations_remaining = max_token_colorizations - colorizations_from_this_pxl_id;
    with_attr error_message(
            "You have reached the max number of allowed colorizations for this rtwrk") {
        assert_le(pixel_colorizations_len, colorizations_remaining);
    }

    // Then total max colorizations allowed
    let total_colorizations_remaining = MAX_TOTAL_COLORIZATIONS - total_colorizations_count;
    with_attr error_message(
            "The max total number of allowed colorizations for this rtwrk has been reached") {
        assert_le(pixel_colorizations_len, total_colorizations_remaining);
    }

    // We can pack up to 8 colorizations per felt so we need to split
    save_pixel_colorizations_per_batch(
        rtwrk_id, pxl_id, pixel_colorizations_len, pixel_colorizations, stored_colorization_len
    );
    number_of_pixel_colorizations_per_colorizer.write(
        rtwrk_id, pxl_id, colorizations_from_this_pxl_id + pixel_colorizations_len
    );
    number_of_pixel_colorizations_total.write(
        rtwrk_id, total_colorizations_count + pixel_colorizations_len
    );

    return ();
}

func save_pixel_colorizations_per_batch{
    pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr
}(
    rtwrk_id: felt,
    pxl_id: Uint256,
    pixel_colorizations_len: felt,
    pixel_colorizations: PixelColorization*,
    already_stored_len: felt,
) {
    let (current_batch: PixelColorization*) = alloc();
    _save_pixel_colorizations_per_batch(
        rtwrk_id,
        pxl_id,
        pixel_colorizations_len,
        pixel_colorizations,
        already_stored_len,
        0,
        current_batch,
    );
    return ();
}

func should_save_to_slot{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    new_batch_len: felt, remaining_pixel_colorizations_len: felt
) -> (should_save: felt) {
    if (new_batch_len == MAX_COLORIZATIONS_PER_FELT) {
        return (TRUE,);
    }
    if (remaining_pixel_colorizations_len == 0) {
        let current_match_not_empty = is_le(1, new_batch_len);
        return (current_match_not_empty,);
    }
    return (FALSE,);
}

func _save_pixel_colorizations_per_batch{
    pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr
}(
    rtwrk_id: felt,
    pxl_id: Uint256,
    remaining_pixel_colorizations_len: felt,
    remaining_pixel_colorizations: PixelColorization*,
    already_stored_len: felt,
    current_batch_len: felt,
    current_batch: PixelColorization*,
) {
    if (remaining_pixel_colorizations_len == 0) {
        // Saving the new index!
        rtwrk_colorization_index.write(rtwrk_id, already_stored_len);
        return ();
    }

    // Need to append to current bach
    assert current_batch[current_batch_len] = remaining_pixel_colorizations[0];

    // We must save to a slot for two reasons:
    // - we have reached MAX_COLORIZATIONS_PER_FELT
    // - we have reached end of remaining colorizations and batch not empty

    let (should_save) = should_save_to_slot(
        current_batch_len + 1, remaining_pixel_colorizations_len - 1
    );

    if (should_save == TRUE) {
        // Pack in a single felt
        let (packed_value_to_save) = pack_colorization(
            Colorization(pxl_id, current_batch_len + 1, current_batch)
        );
        // Save in a new slot
        rtwrk_colorizations.write(rtwrk_id, already_stored_len, packed_value_to_save);
        let (new_batch: PixelColorization*) = alloc();
        return _save_pixel_colorizations_per_batch(
            rtwrk_id,
            pxl_id,
            remaining_pixel_colorizations_len - 1,
            remaining_pixel_colorizations + PixelColorization.SIZE,
            already_stored_len + 1,
            0,
            new_batch,
        );
    } else {
        return _save_pixel_colorizations_per_batch(
            rtwrk_id,
            pxl_id,
            remaining_pixel_colorizations_len - 1,
            remaining_pixel_colorizations + PixelColorization.SIZE,
            already_stored_len,
            current_batch_len + 1,
            current_batch,
        );
    }
}

func reverse_pixel_colorizations{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    pixel_colorizations_len: felt, pixel_colorizations: PixelColorization*
) -> (pixel_colorizations_len: felt, pixel_colorizations: PixelColorization*) {
    let (pixel_colorizations_reversed: PixelColorization*) = alloc();
    return _reverse_pixel_colorizations(
        pixel_colorizations_len, pixel_colorizations, 0, pixel_colorizations_reversed
    );
}

func _reverse_pixel_colorizations{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    pixel_colorizations_len: felt,
    pixel_colorizations: PixelColorization*,
    pixel_colorizations_reversed_len: felt,
    pixel_colorizations_reversed: PixelColorization*,
) -> (pixel_colorizations_len: felt, pixel_colorizations: PixelColorization*) {
    if (pixel_colorizations_len == 0) {
        return (pixel_colorizations_reversed_len, pixel_colorizations_reversed);
    }
    assert pixel_colorizations_reversed[pixel_colorizations_reversed_len] = pixel_colorizations[pixel_colorizations_len - 1];
    return _reverse_pixel_colorizations(
        pixel_colorizations_len - 1,
        pixel_colorizations,
        pixel_colorizations_reversed_len + 1,
        pixel_colorizations_reversed,
    );
}

func get_colorizers{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    rtwrk_id: felt, rtwrk_step: felt
) -> (colorizers_len: felt, colorizers: felt*) {
    alloc_locals;
    // Returns the number of pxlId (= number of people)
    // that did at least one colorization during a given rtwrk

    let (colorizations_len: felt, colorizations: Colorization*) = get_all_rtwrk_colorizations(
        rtwrk_id, rtwrk_step
    );

    let (pxl_id_has_colorizations: DictAccess*) = default_dict_new(default_value=FALSE);
    default_dict_finalize(pxl_id_has_colorizations, pxl_id_has_colorizations, FALSE);
    let (colorizers: felt*) = alloc();
    let (colorizers_len, colorizers) = fill_colorizations_per_pxl_id(
        0, colorizers, pxl_id_has_colorizations, colorizations_len, colorizations
    );
    return (colorizers_len, colorizers);
}

func fill_colorizations_per_pxl_id{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    colorizers_len: felt,
    colorizers: felt*,
    pxl_id_has_colorizations: DictAccess*,
    colorizations_len: felt,
    colorizations: Colorization*,
) -> (colorizers_len: felt, colorizers: felt*) {
    if (colorizations_len == 0) {
        return (colorizers_len, colorizers);
    }
    let pxl_id = colorizations[0].pxl_id;
    let (pxl_has_already_colorized) = dict_read{dict_ptr=pxl_id_has_colorizations}(key=pxl_id.low);
    if (pxl_has_already_colorized == TRUE) {
        return fill_colorizations_per_pxl_id(
            colorizers_len,
            colorizers,
            pxl_id_has_colorizations,
            colorizations_len - 1,
            colorizations + Colorization.SIZE,
        );
    } else {
        dict_write{dict_ptr=pxl_id_has_colorizations}(key=pxl_id.low, new_value=TRUE);
        assert colorizers[colorizers_len] = pxl_id.low;
        return fill_colorizations_per_pxl_id(
            colorizers_len + 1,
            colorizers,
            pxl_id_has_colorizations,
            colorizations_len - 1,
            colorizations + Colorization.SIZE,
        );
    }
}
