%lang starknet
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math_cmp import is_le
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.starknet.common.syscalls import get_block_timestamp

from pxls.PixelDrawer.storage import current_drawing_round, drawing_timestamp, drawing_theme

// 1 full day in seconds (get_block_timestamp returns timestamp in seconds)
// 24 hours + margin of 2 hours for block time
const DAY_DURATION = 93600;

//
// Methods about the current round, if a round
// exists, and if we should launch a new round
//

func assert_round_exists{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    round: felt
) {
    alloc_locals;
    let (current_round) = current_drawing_round.read();
    let round_exists = is_le(round, current_round);
    with_attr error_message("Round {round} does not exist") {
        assert round_exists = TRUE;
    }
    return ();
}

func assert_current_round_running{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    ) {
    let (should_launch) = should_launch_new_round();
    with_attr error_message("This drawing round is finished, please launch a new one") {
        assert should_launch = FALSE;
    }
    return ();
}

func should_launch_new_round{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    should_launch: felt
) {
    alloc_locals;
    let (block_timestamp) = get_block_timestamp();
    let (last_drawing_timestamp) = current_drawing_timestamp();
    let duration = block_timestamp - last_drawing_timestamp;
    // if duration >= DAY_DURATION (last drawing lasted 1 day)
    let should_launch = is_le(DAY_DURATION, duration);
    return (should_launch=should_launch);
}

func launch_new_round{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    theme_len: felt, theme: felt*
) {
    alloc_locals;
    let (current_round) = current_drawing_round.read();
    let new_round = current_round + 1;
    current_drawing_round.write(new_round);
    let (block_timestamp) = get_block_timestamp();
    drawing_timestamp.write(new_round, block_timestamp);

    store_theme(new_round, 0, theme_len, theme);

    return ();
}

func store_theme{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    round: felt, theme_index: felt, theme_len: felt, theme: felt*
) {
    if (theme_len == 0) {
        return ();
    }
    let theme_component = theme[0];
    drawing_theme.write(round, theme_index, theme_component);
    return store_theme(round, theme_index + 1, theme_len - 1, theme + 1);
}

func read_theme{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(round: felt) -> (
    theme_len: felt, theme: felt*
) {
    alloc_locals;
    let (theme: felt*) = alloc();
    let (theme_len) = _read_theme(round, 0, theme);
    return (theme_len, theme);
}

func _read_theme{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    round: felt, theme_len: felt, theme: felt*
) -> (theme_len: felt) {
    let (theme_component) = drawing_theme.read(round, theme_len);
    if (theme_component == 0) {
        return (theme_len,);
    } else {
        assert theme[theme_len] = theme_component;
        return _read_theme(round, theme_len + 1, theme);
    }
}

func launch_new_round_if_necessary{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    theme_len: felt, theme: felt*
) -> (launched: felt) {
    let (should_launch) = should_launch_new_round();
    if (should_launch == TRUE) {
        launch_new_round(theme_len, theme);
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
// Methods about the round timestamp
//

func get_drawing_timestamp{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    round: felt
) -> (timestamp: felt) {
    let (timestamp) = drawing_timestamp.read(round);
    return (timestamp=timestamp);
}

func current_drawing_timestamp{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    ) -> (timestamp: felt) {
    let (round) = current_drawing_round.read();
    return get_drawing_timestamp(round);
}
