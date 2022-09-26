%lang starknet
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import get_block_timestamp
from starkware.cairo.common.math_cmp import is_le
from starkware.cairo.common.bool import TRUE, FALSE

from pxls.RtwrkThemeAuction.storage import current_auction_id, auction_timestamp
from pxls.RtwrkThemeAuction.variables import BLOCK_TIME_BUFFER

// 1 full day in seconds (get_block_timestamp returns timestamp in seconds)
const DAY_DURATION = 24 * 3600;
const DAY_DURATION_WITH_BUFFER = DAY_DURATION + BLOCK_TIME_BUFFER;

func is_running_auction{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    running_auction: felt
) {
    let (current_id: felt) = current_auction_id.read();
    let (current_auction_timestamp: felt) = auction_timestamp.read(current_id);

    let (block_timestamp) = get_block_timestamp();
    let duration = block_timestamp - current_auction_timestamp;
    // Testing if DAY_DURATION_WITH_BUFFER <= duration
    // so if it's 1, auction has ended
    let auction_ended = is_le(DAY_DURATION_WITH_BUFFER, duration);
    // So we need to return the contrary to check if running auction
    return (running_auction=1 - auction_ended);
}

func assert_running_auction{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    let (running_auction: felt) = is_running_auction();
    with_attr error_message("There is currently no running auction") {
        assert running_auction = TRUE;
    }
    return ();
}

func assert_no_running_auction{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    let (running_auction: felt) = is_running_auction();
    with_attr error_message("Cannot call this method while an auction is running") {
        assert running_auction = FALSE;
    }
    return ();
}

func launch_auction{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    assert_no_running_auction();
    let (current_id: felt) = current_auction_id.read();
    let new_auction_id = current_id + 1;
    let (block_timestamp) = get_block_timestamp();
    current_auction_id.write(new_auction_id);
    auction_timestamp.write(new_auction_id, block_timestamp);
    return ();
}
