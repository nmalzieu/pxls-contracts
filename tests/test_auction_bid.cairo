%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.alloc import alloc

from pxls.RtwrkThemeAuction.bid import (
    store_bid_theme,
    read_bid_theme,
    Bid,
    store_bid,
    read_bid,
    assert_bid_valid,
    place_bid,
)
from pxls.RtwrkThemeAuction.storage import (
    auction_bids_count,
    current_auction_id,
    auction_timestamp,
    eth_erc20_address,
    bid_reimbursement_timestamp,
)

@view
func test_store_bid_theme{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}() {
    let (theme: felt*) = alloc();
    assert theme[0] = 'My super theme';
    assert theme[1] = 'is many felts';
    assert theme[2] = 'exactly 3';
    store_bid_theme(auction_id=12, bid_id=1, theme_index=0, theme_len=3, theme=theme);

    let (stored_theme_len: felt, stored_theme: felt*) = read_bid_theme(12, 1);
    assert 3 = stored_theme_len;
    assert 'My super theme' = stored_theme[0];
    assert 'is many felts' = stored_theme[1];
    assert 'exactly 3' = stored_theme[2];

    return ();
}

@view
func test_store_bid{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}() {
    let (bids_count) = auction_bids_count.read(2);

    assert 0 = bids_count;

    let (theme: felt*) = alloc();
    assert theme[0] = 'My super theme';
    assert theme[1] = 'is many felts';
    assert theme[2] = 'exactly 3';

    let bid = Bid(
        account='account',
        amount=12,
        timestamp=1664192254,
        reimbursement_timestamp=12,
        theme_len=3,
        theme=theme,
    );
    store_bid(auction_id=2, bid=bid);

    let (bids_count) = auction_bids_count.read(2);
    assert 1 = bids_count;

    let (stored_bid) = read_bid(auction_id=2, bid_id=0);

    assert 12 = stored_bid.amount;
    assert 'account' = stored_bid.account;
    assert 3 = stored_bid.theme_len;
    assert 'My super theme' = stored_bid.theme[0];
    assert 'is many felts' = stored_bid.theme[1];
    assert 'exactly 3' = stored_bid.theme[2];
    assert 1664192254 = stored_bid.timestamp;
    assert 0 = stored_bid.reimbursement_timestamp;  // This is not updated via store_bid

    let (unexistent_stored_bid) = read_bid(auction_id=2, bid_id=1);

    assert 0 = unexistent_stored_bid.amount;
    assert 0 = unexistent_stored_bid.account;
    assert 0 = unexistent_stored_bid.theme_len;
    assert 0 = unexistent_stored_bid.timestamp;

    return ();
}

@view
func test_validate_bid_theme_too_long{
    syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}() {
    let (theme: felt*) = alloc();
    assert theme[0] = 'My super theme';
    assert theme[1] = 'is many felts';
    assert theme[2] = 'exactly 6';
    assert theme[3] = 'too';
    assert theme[4] = 'bad';
    assert theme[5] = 'fren';

    let bid = Bid(
        account='account',
        amount=12,
        timestamp=1664192254,
        reimbursement_timestamp=0,
        theme_len=6,
        theme=theme,
    );

    %{ expect_revert(error_message="Theme is too long") %}
    assert_bid_valid(auction_id=2, bid=bid);

    return ();
}

@view
func test_validate_first_bid_amount_too_low{
    syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}() {
    alloc_locals;
    let (theme: felt*) = alloc();
    assert theme[0] = 'My super theme';

    let bid = Bid(
        account='account',
        amount=2000000000000000,
        timestamp=1664192254,
        reimbursement_timestamp=0,
        theme_len=1,
        theme=theme,
    );

    %{ expect_revert(error_message="Bid amount must be at least 5000000000000000 since last bid is 0") %}
    assert_bid_valid(auction_id=2, bid=bid);

    return ();
}

@view
func test_validate_second_bid_amount_too_low{
    syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}() {
    alloc_locals;
    let (theme: felt*) = alloc();
    assert theme[0] = 'My super theme';

    let bid = Bid(
        account='account',
        amount=7000000000000000,
        timestamp=1664192254,
        reimbursement_timestamp=0,
        theme_len=1,
        theme=theme,
    );

    assert_bid_valid(auction_id=2, bid=bid);
    store_bid(auction_id=2, bid=bid);

    let bid = Bid(
        account='account',
        amount=0,
        timestamp=1664192254,
        reimbursement_timestamp=0,
        theme_len=1,
        theme=theme,
    );

    %{ expect_revert(error_message="Bid amount must be at least 12000000000000000 since last bid is 7000000000000000") %}
    assert_bid_valid(auction_id=2, bid=bid);

    return ();
}

@view
func test_place_bid{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}() {
    alloc_locals;

    %{ warp(1664192254) %}
    %{ stop_prank = start_prank(121212) %}

    current_auction_id.write(12);
    auction_timestamp.write(12, 1664192254);
    let eth_erc20_address_value = 'eth_erc20_address';
    eth_erc20_address.write(eth_erc20_address_value);

    let (count) = auction_bids_count.read(12);
    assert 0 = count;

    let (local theme: felt*) = alloc();
    assert theme[0] = 'My super theme';
    assert theme[1] = 'is many felts';
    assert theme[2] = 'exactly 3';

    // Mocking the erc20 transferFrom
    %{ stop_mock_erc20 = mock_call(ids.eth_erc20_address_value, "transferFrom", []) %}

    place_bid(auction_id=12, bid_amount=5000000000000000, theme_len=3, theme=theme);

    // Verify that new bid was saved

    let (count) = auction_bids_count.read(12);
    assert 1 = count;

    // Verify data from the new bid
    let (stored_bid) = read_bid(auction_id=12, bid_id=0);
    assert 5000000000000000 = stored_bid.amount;
    assert 121212 = stored_bid.account;
    assert 1664192254 = stored_bid.timestamp;
    assert 3 = stored_bid.theme_len;
    assert 'My super theme' = stored_bid.theme[0];
    assert 'is many felts' = stored_bid.theme[1];
    assert 'exactly 3' = stored_bid.theme[2];

    // New bid is not reimbursed

    let (timestamp) = bid_reimbursement_timestamp.read(12, 0);
    assert 0 = timestamp;

    // Mocking the erc20 transferFrom
    %{ stop_mock_erc20 = mock_call(ids.eth_erc20_address_value, "transfer", []) %}

    // Place another bid

    place_bid(auction_id=12, bid_amount=12000000000000000, theme_len=3, theme=theme);

    // Verify that it was saved

    let (count) = auction_bids_count.read(12);
    assert 2 = count;

    // Verify that first one was reimbursed
    let (stored_bid) = read_bid(auction_id=12, bid_id=0);
    assert 1664192254 = stored_bid.reimbursement_timestamp;

    // Verify that new one not reimbursed
    let (stored_bid) = read_bid(auction_id=12, bid_id=1);
    assert 0 = stored_bid.reimbursement_timestamp;

    return ();
}
