%lang starknet
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.default_dict import default_dict_new, default_dict_finalize
from starkware.cairo.common.dict_access import DictAccess
from starkware.cairo.common.dict import dict_write, dict_read

from pxls.PixelDrawer.colorization import (
    Colorization,
    UserColorizations,
    get_all_drawing_user_colorizations,
)
from pxls.PixelDrawer.palette import get_palette_color

func get_grid{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    round: felt, max_supply: felt
) -> (grid_len: felt, grid: felt*) {
    alloc_locals;
    // Let's get all colorizations for this round
    let (
        user_colorizations_len: felt, user_colorizations: UserColorizations*
    ) = get_all_drawing_user_colorizations(round);

    let (grid: felt*) = alloc();

    fill_grid(max_supply, grid, user_colorizations_len, user_colorizations);

    return (max_supply * 4, grid);
}

func fill_grid{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}(
    grid_len: felt,
    grid: felt*,
    user_colorizations_len: felt,
    user_colorizations: UserColorizations*,
) {
    alloc_locals;
    let (grid_dict: DictAccess*) = default_dict_new(default_value=-1);
    default_dict_finalize(grid_dict, grid_dict, -1);
    _fill_grid_dict{
        dict_ptr=grid_dict,
        syscall_ptr=syscall_ptr,
        range_check_ptr=range_check_ptr,
        pedersen_ptr=pedersen_ptr,
    }(user_colorizations_len, user_colorizations);
    _fill_grid_from_dict{
        dict_ptr=grid_dict,
        syscall_ptr=syscall_ptr,
        range_check_ptr=range_check_ptr,
        pedersen_ptr=pedersen_ptr,
    }(grid_len, grid, 0);
    return ();
}

func _fill_grid_dict{
    dict_ptr: DictAccess*, syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}(user_colorizations_len: felt, user_colorizations: UserColorizations*) {
    if (user_colorizations_len == 0) {
        return ();
    }
    let user_colorization = user_colorizations[0];
    _fill_grid_dict_with_user_colorization(
        user_colorization.colorizations_len, user_colorization.colorizations
    );
    return _fill_grid_dict(user_colorizations_len - 1, user_colorizations + UserColorizations.SIZE);
}

func _fill_grid_dict_with_user_colorization{
    dict_ptr: DictAccess*, syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}(colorizations_len: felt, colorizations: Colorization*) {
    if (colorizations_len == 0) {
        return ();
    }
    let colorization = colorizations[0];
    dict_write(key=colorization.pixel_index, new_value=colorization.color_index);
    return _fill_grid_dict_with_user_colorization(
        colorizations_len - 1, colorizations + Colorization.SIZE
    );
}

func _fill_grid_from_dict{
    dict_ptr: DictAccess*, syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}(grid_len: felt, grid: felt*, pixel_index: felt) {
    if (pixel_index == grid_len) {
        return ();
    }
    let (color_index) = dict_read(key=pixel_index);
    if (color_index == -1) {
        assert grid[4 * pixel_index] = FALSE;
        assert grid[4 * pixel_index + 1] = 0;
        assert grid[4 * pixel_index + 2] = 0;
        assert grid[4 * pixel_index + 3] = 0;
        return _fill_grid_from_dict(grid_len, grid, pixel_index + 1);
    } else {
        let (color) = get_palette_color(color_index);
        assert grid[4 * pixel_index] = TRUE;
        assert grid[4 * pixel_index + 1] = color.red;
        assert grid[4 * pixel_index + 2] = color.green;
        assert grid[4 * pixel_index + 3] = color.blue;
        return _fill_grid_from_dict(grid_len, grid, pixel_index + 1);
    }
}
