%lang starknet
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math_cmp import is_le
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.starknet.common.syscalls import get_block_timestamp

from pxls.RtwrkDrawer.storage import current_rtwrk_id, rtwrk_timestamp, rtwrk_theme
from pxls.RtwrkDrawer.variables import BLOCK_TIME_BUFFER

// 1 full day in seconds (get_block_timestamp returns timestamp in seconds)
const DAY_DURATION = 24 * 3600;

const DAY_DURATION_WITH_BUFFER = DAY_DURATION + BLOCK_TIME_BUFFER;

//
// Methods about the current rtwrk, if a rtwrk
// exists, and if we should launch a new rtwrk
//

func assert_rtwrk_id_exists{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    rtwrk_id: felt
) {
    alloc_locals;
    let (current_rtwrk_id_value) = current_rtwrk_id.read();
    let rtwrk_id_exists = is_le(rtwrk_id, current_rtwrk_id_value);
    with_attr error_message("Rtwrk id {rtwrk_id} does not exist") {
        assert rtwrk_id_exists = TRUE;
    }
    return ();
}

func assert_current_rtwrk_running{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    ) {
    let (should_launch) = should_launch_new_rtwrk();
    with_attr error_message("This rtwrk is finished, please launch a new one") {
        assert should_launch = FALSE;
    }
    return ();
}

func should_launch_new_rtwrk{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    should_launch: felt
) {
    alloc_locals;
    let (block_timestamp) = get_block_timestamp();
    let (last_rtwrk_timestamp) = current_rtwrk_timestamp();
    let duration = block_timestamp - last_rtwrk_timestamp;
    // if duration >= DAY_DURATION_WITH_BUFFER (last drawing lasted 1 day)
    let should_launch = is_le(DAY_DURATION_WITH_BUFFER, duration);
    return (should_launch=should_launch);
}

func launch_new_rtwrk{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    theme_len: felt, theme: felt*
) {
    alloc_locals;
    let (current_rtwrk_id_value) = current_rtwrk_id.read();
    let new_rtwrk_id = current_rtwrk_id_value + 1;
    current_rtwrk_id.write(new_rtwrk_id);
    let (block_timestamp) = get_block_timestamp();
    rtwrk_timestamp.write(new_rtwrk_id, block_timestamp);

    store_theme(new_rtwrk_id, 0, theme_len, theme);

    return ();
}

func store_theme{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    rtwrk_id: felt, theme_index: felt, theme_len: felt, theme: felt*
) {
    if (theme_len == 0) {
        return ();
    }
    let theme_component = theme[0];
    rtwrk_theme.write(rtwrk_id, theme_index, theme_component);
    return store_theme(rtwrk_id, theme_index + 1, theme_len - 1, theme + 1);
}

func read_theme{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(rtwrk_id: felt) -> (
    theme_len: felt, theme: felt*
) {
    alloc_locals;
    let (theme: felt*) = alloc();
    let (theme_len) = _read_theme(rtwrk_id, 0, theme);
    return (theme_len, theme);
}

func _read_theme{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    rtwrk_id: felt, theme_len: felt, theme: felt*
) -> (theme_len: felt) {
    let (theme_component) = rtwrk_theme.read(rtwrk_id, theme_len);
    if (theme_component == 0) {
        return (theme_len,);
    } else {
        assert theme[theme_len] = theme_component;
        return _read_theme(rtwrk_id, theme_len + 1, theme);
    }
}

func launch_new_rtwrk_if_necessary{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    theme_len: felt, theme: felt*
) -> (launched: felt) {
    let (should_launch) = should_launch_new_rtwrk();
    if (should_launch == TRUE) {
        launch_new_rtwrk(theme_len, theme);
        // See https://www.cairo-lang.org/docs/how_cairo_works/builtins.html#revoked-implicit-arguments
        tempvar syscall_ptr = syscall_ptr;
        tempvar pedersen_ptr = pedersen_ptr;
        tempvar range_check_ptr = range_check_ptr;
        return (launched=TRUE);
    } else {
        tempvar syscall_ptr = syscall_ptr;
        tempvar pedersen_ptr = pedersen_ptr;
        tempvar range_check_ptr = range_check_ptr;
        return (launched=FALSE);
    }
}

//
// Methods about the rtwrk timestamp
//

func get_rtwrk_timestamp{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    rtwrk_id: felt
) -> (timestamp: felt) {
    let (timestamp) = rtwrk_timestamp.read(rtwrk_id);
    return (timestamp=timestamp);
}

func current_rtwrk_timestamp{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    ) -> (timestamp: felt) {
    let (rtwrk_id) = current_rtwrk_id.read();
    return get_rtwrk_timestamp(rtwrk_id);
}
