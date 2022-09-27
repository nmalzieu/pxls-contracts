%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.bool import TRUE, FALSE

from pxls.RtwrkThemeAuction.auction import is_running_auction, launch_auction, launch_auction_rtwrk
from pxls.RtwrkThemeAuction.storage import (
    auction_timestamp,
    current_auction_id,
    rtwrk_drawer_address,
    rtwrk_erc721_address,
)

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

    let rtwrk_contract_address = 'rtwrk_contract_address';
    rtwrk_drawer_address.write(rtwrk_contract_address);

    let rtwrk_collection_address = 'rtwrk_collection_address';
    rtwrk_erc721_address.write(rtwrk_collection_address);

    %{ stop_mock_rtwrk_id = mock_call(ids.rtwrk_contract_address, "currentRtwrkId", [1]) %}
    %{ stop_mock_rtwrk_timestamp = mock_call(ids.rtwrk_contract_address, "rtwrkTimestamp", [1664192254 - 26 * 3600]) %}
    %{ stop_mock_rtwrk_minted = mock_call(ids.rtwrk_collection_address, "exists", [1]) %}

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

@view
func test_launch_auction_rtwrk_running{
    syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}() {
    %{ warp(1664192254) %}

    let rtwrk_contract_address = 'rtwrk_contract_address';
    rtwrk_drawer_address.write(rtwrk_contract_address);

    %{ stop_mock_rtwrk_id = mock_call(ids.rtwrk_contract_address, "currentRtwrkId", [1]) %}
    %{ stop_mock_rtwrk_timestamp = mock_call(ids.rtwrk_contract_address, "rtwrkTimestamp", [1664192254]) %}

    let (running) = is_running_auction();
    assert FALSE = running;
    let (current_id) = current_auction_id.read();
    assert 0 = current_id;

    %{ expect_revert(error_message="Cannot call this method while an rtwrk is running") %}
    launch_auction();

    return ();
}

@view
func test_launch_auction_last_rtwrk_not_minted{
    syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}() {
    %{ warp(1664192254) %}

    let rtwrk_contract_address = 'rtwrk_contract_address';
    rtwrk_drawer_address.write(rtwrk_contract_address);

    let rtwrk_collection_address = 'rtwrk_collection_address';
    rtwrk_erc721_address.write(rtwrk_collection_address);

    %{ stop_mock_rtwrk_id = mock_call(ids.rtwrk_contract_address, "currentRtwrkId", [1]) %}
    %{ stop_mock_rtwrk_timestamp = mock_call(ids.rtwrk_contract_address, "rtwrkTimestamp", [1664192254 - 26 * 3600]) %}
    %{ stop_mock_rtwrk_minted = mock_call(ids.rtwrk_collection_address, "exists", [0]) %}

    let (running) = is_running_auction();
    assert FALSE = running;
    let (current_id) = current_auction_id.read();
    assert 0 = current_id;

    %{ expect_revert(error_message="Rtwrk 1 has not been minted") %}
    launch_auction();

    return ();
}

@view
func test_launch_auction_rtwrk_no_auction{
    syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}() {
    %{ expect_revert(error_message="No auction has ever been launched") %}
    launch_auction_rtwrk();

    return ();
}

@view
func test_launch_auction_rtwrk_auction_running{
    syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}() {
    launch_auction_with_mock();

    %{ expect_revert(error_message="Cannot call this method while an auction is running") %}
    launch_auction_rtwrk();

    return ();
}

@view
func test_launch_auction_rtwrk_auction_done{
    syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}() {
    launch_auction_with_mock();
    %{ warp(1664192254 + 26*3600) %}

    launch_auction_rtwrk();

    // Cannot launch rtwrk twice
    %{ expect_revert(error_message="Rtwrk for auction 1 has already been launched at timestamp 1664285854") %}
    launch_auction_rtwrk();

    return ();
}

func launch_auction_with_mock{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}() {
    %{ warp(1664192254) %}
    let rtwrk_contract_address = 'rtwrk_contract_address';
    rtwrk_drawer_address.write(rtwrk_contract_address);
    let rtwrk_collection_address = 'rtwrk_collection_address';
    rtwrk_erc721_address.write(rtwrk_collection_address);
    %{ stop_mock_rtwrk_id = mock_call(ids.rtwrk_contract_address, "currentRtwrkId", [1]) %}
    %{ stop_mock_rtwrk_timestamp = mock_call(ids.rtwrk_contract_address, "rtwrkTimestamp", [1664192254 - 26 * 3600]) %}
    %{ stop_mock_rtwrk_minted = mock_call(ids.rtwrk_collection_address, "exists", [1]) %}
    launch_auction();
    return ();
}
