%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.bool import TRUE, FALSE

from pxls.RtwrkThemeAuction.auction import is_running_auction, launch_auction
from pxls.RtwrkThemeAuction.storage import auction_timestamp, current_auction_id

@view
func test_is_running_auction{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}() {
    auction_timestamp.write(1, 1664192254);
    current_auction_id.write(1);

    // After 23 hours, still running
    %{ warp(1664192254 + 23*3600) %}
    let (running) = is_running_auction();
    assert TRUE = running;

    // After 25 hours, still running (because there is a buffer)
    %{ warp(1664192254 + 25*3600) %}
    let (running) = is_running_auction();
    assert TRUE = running;

    // After 26 hours, not running anymore (buffer is 2 hours)
    %{ warp(1664192254 + 26*3600) %}
    let (running) = is_running_auction();
    assert FALSE = running;

    return ();
}



@view
func test_launch_auction{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}() {
    %{ warp(1664192254) %}
    let (running) = is_running_auction();
    assert FALSE = running;
    let (current_id) = current_auction_id.read();
    assert 0 = current_id;

    launch_auction();

    let (running) = is_running_auction();
    assert TRUE = running;
    let (current_id) = current_auction_id.read();
    assert 1 = current_id;
    let (timestamp) = auction_timestamp.read(current_id);
    assert 1664192254 = timestamp;

    %{ expect_revert(error_message="Cannot call this method while an auction is running") %}
    launch_auction();

    return ();
}
