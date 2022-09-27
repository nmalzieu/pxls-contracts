%lang starknet
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import get_block_timestamp
from starkware.cairo.common.math_cmp import is_le
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.math import assert_le

from pxls.RtwrkThemeAuction.storage import current_auction_id, auction_timestamp, auction_bids_count
from pxls.RtwrkThemeAuction.variables import BLOCK_TIME_BUFFER

// 1 full day in seconds (get_block_timestamp returns timestamp in seconds)
const DAY_DURATION = 24 * 3600;
const DAY_DURATION_WITH_BUFFER = DAY_DURATION + BLOCK_TIME_BUFFER;

func is_running_auction{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    running_auction: felt
) {
    let (current_id: felt) = current_auction_id.read();
    if (current_id == 0) {
        // No auction has ever been launched
        return (running_auction=FALSE);
    }
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

func assert_running_auction_id{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    auction_id: felt
) {
    alloc_locals;
    let (local current_id: felt) = current_auction_id.read();
    with_attr error_message("Current auction is {current_id}, not {auction_id}") {
        assert current_id = auction_id;
    }
    assert_running_auction();
    return ();
}

func assert_no_running_auction{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    let (running_auction: felt) = is_running_auction();
    with_attr error_message("Cannot call this method while an auction is running") {
        assert running_auction = FALSE;
    }
    return ();
}

func assert_auction_has_bids{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    auction_id
) {
    let (bids_cound: felt) = auction_bids_count.read(auction_id);
    with_attr error_message("Auction {auction_id} has no bids") {
        assert_le(1, bids_cound);
    }
    return ();
}
