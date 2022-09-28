%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.uint256 import Uint256

from pxls.RtwrkThemeAuction.auction import launch_auction, launch_auction_rtwrk, settle_auction
from pxls.RtwrkThemeAuction.bid import place_bid
from pxls.RtwrkThemeAuction.auction_checks import is_running_auction
from pxls.RtwrkThemeAuction.storage import (
    auction_timestamp,
    current_auction_id,
    rtwrk_drawer_address,
    rtwrk_erc721_address,
    eth_erc20_address,
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
func test_launch_auction_event{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}() {
    %{ warp(1664192254) %}
    %{ start_prank(654321) %}

    let rtwrk_contract_address = 'rtwrk_contract_address';
    rtwrk_drawer_address.write(rtwrk_contract_address);

    let rtwrk_collection_address = 'rtwrk_collection_address';
    rtwrk_erc721_address.write(rtwrk_collection_address);

    %{ stop_mock_rtwrk_id = mock_call(ids.rtwrk_contract_address, "currentRtwrkId", [1]) %}
    %{ stop_mock_rtwrk_timestamp = mock_call(ids.rtwrk_contract_address, "rtwrkTimestamp", [1664192254 - 26 * 3600]) %}
    %{ stop_mock_rtwrk_minted = mock_call(ids.rtwrk_collection_address, "exists", [1]) %}

    %{
        expect_events({
               "name": "auction_launched",
               "data": {
                   "caller_account_address": 654321,
                   "auction_id": 1,
               }
           })
    %}

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
func test_launch_auction_rtwrk_auction_no_bids{
    syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}() {
    launch_auction_with_mock();
    %{ warp(1664192254 + 26*3600) %}

    %{ expect_revert(error_message="Auction 1 has no bids") %}
    launch_auction_rtwrk();

    return ();
}

@view
func test_launch_auction_rtwrk_drawer_cant_launch{
    syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}() {
    launch_auction_with_mock();

    let eth_erc20_address_value = 'eth_erc20_address';
    eth_erc20_address.write(eth_erc20_address_value);

    let (theme: felt*) = alloc();
    assert theme[0] = 'Theme 1';

    // Mocking the erc20 transferFrom
    %{ stop_mock_erc20 = mock_call(ids.eth_erc20_address_value, "transferFrom", [1]) %}

    place_bid(auction_id=1, bid_amount=Uint256(5000000000000000, 0), theme_len=1, theme=theme);

    %{ warp(1664192254 + 26*3600) %}

    let rtwrk_contract_address = 'rtwrk_contract_address';
    %{ stop_mock_rtwrk_launch = mock_call(ids.rtwrk_contract_address, "launchNewRtwrkIfNecessary", [0]) %}
    %{ expect_revert(error_message="An error occured, the rtwrk could not be launched") %}
    launch_auction_rtwrk();

    return ();
}

@view
func test_launch_auction_rtwrk_cant_launch_twice{
    syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}() {
    launch_auction_and_rtwrk_with_mock();

    // Cannot launch rtwrk twice
    %{ expect_revert(error_message="Rtwrk for auction 1 has already been launched at timestamp 1664285854") %}
    launch_auction_rtwrk();

    return ();
}

@view
func test_launch_auction_rtwrk{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}() {
    %{ start_prank(654321) %}

    %{
        expect_events({
               "name": "rtwrk_launched",
               "data": {
                   "caller_account_address": 654321,
                   "auction_id": 1,
                   "rtwrk_id": 1,
                   "theme": [23758682880024625]
               }
           })
    %}

    launch_auction_and_rtwrk_with_mock();

    return ();
}

@view
func test_settle_auction_no_auction{
    syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}() {
    %{ expect_revert(error_message="No auction has ever been launched") %}
    settle_auction();
    return ();
}

@view
func test_settle_auction_still_running{
    syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}() {
    launch_auction_with_mock();
    %{ expect_revert(error_message="Cannot call this method while an auction is running") %}
    settle_auction();
    return ();
}

@view
func test_settle_auction_no_bids{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}(
    ) {
    launch_auction_with_mock();
    // Auction is finished, but rtwrk was not launched
    %{ warp(1664192254 + 26 * 3600) %}
    %{ expect_revert(error_message="Auction 1 has no bids") %}
    settle_auction();
    return ();
}

@view
func test_settle_auction_rtwrk_not_launched{
    syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}() {
    launch_auction_and_bids_with_mock();
    // Auction is finished, but rtwrk was not launched
    %{ warp(1664192254 + 26 * 3600) %}
    %{ expect_revert(error_message="Rtwrk for auction 1 has not yet been launched so auction cannot be settled") %}
    settle_auction();
    return ();
}

@view
func test_settle_auction_rtwrk_not_finished{
    syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}() {
    launch_auction_and_rtwrk_with_mock();
    // Rtwrk is launched, but not yet finished
    %{ warp(1664192254 + 26*3600 + 24*3600) %}
    %{ expect_revert(error_message="Cannot call this method while an rtwrk is running") %}
    settle_auction();
    return ();
}

// Right now this test doesn't work because we need exists to return false
// first (current rtwrk must not be minted when we settle) then true
// (current rtwrk must be minted to launch the next auction)
// Todo => improve protostar to handle this?

// @view
// func test_settle_auction_rtwrk_finished{
//     syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
// }() {
//     %{ start_prank(654321) %}

//     launch_auction_and_rtwrk_with_mock();
//     // Rtwrk is launched, and should be finished after 26 hours
//     %{ warp(1664192254 + 26*3600 + 26*3600) %}
//     // Mock to say that the current rtwrk token hasn't been minted yet
//     %{ stop_mock_rtwrk_minted() %}
//     let rtwrk_collection_address = 'rtwrk_collection_address';
//     rtwrk_erc721_address.write(rtwrk_collection_address);
//     %{ stop_mock_rtwrk_minted = mock_call(ids.rtwrk_collection_address, "exists", [0]) %}
//     %{ stop_mock_rtwrk_mint = mock_call(ids.rtwrk_collection_address, "mint", []) %}

//     %{
//         expect_events({
//                "name": "auction_settled",
//                "data": {
//                    "caller_account_address": 654321,
//                    "winner_account_address": 654321,
//                    "auction_id": 1,
//                    "rtwrk_id": 1
//                }
//            })
//     %}

//     settle_auction();
//     return ();
// }

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

func launch_auction_and_bids_with_mock{
    syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}() {
    launch_auction_with_mock();
    let eth_erc20_address_value = 'eth_erc20_address';
    eth_erc20_address.write(eth_erc20_address_value);

    let (theme: felt*) = alloc();
    assert theme[0] = 'Theme 1';

    // Mocking the erc20 transferFrom
    %{ stop_mock_erc20 = mock_call(ids.eth_erc20_address_value, "transferFrom", [1]) %}

    place_bid(auction_id=1, bid_amount=Uint256(5000000000000000, 0), theme_len=1, theme=theme);

    return ();
}

func launch_auction_and_rtwrk_with_mock{
    syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}() {
    launch_auction_and_bids_with_mock();

    %{ warp(1664192254 + 26*3600) %}

    let rtwrk_contract_address = 'rtwrk_contract_address';
    %{ stop_mock_rtwrk_launch = mock_call(ids.rtwrk_contract_address, "launchNewRtwrkIfNecessary", [1]) %}
    launch_auction_rtwrk();
    %{ stop_mock_rtwrk_id() %}
    %{ stop_mock_rtwrk_timestamp() %}
    %{ stop_mock_rtwrk_id = mock_call(ids.rtwrk_contract_address, "currentRtwrkId", [2]) %}
    %{ stop_mock_rtwrk_timestamp = mock_call(ids.rtwrk_contract_address, "rtwrkTimestamp", [1664192254 + 26*3600]) %}
    return ();
}
