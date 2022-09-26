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
)
from pxls.RtwrkThemeAuction.storage import auction_bids_count

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

    let bid = Bid(account='account', amount=12, theme_len=3, theme=theme);
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

    let (unexistent_stored_bid) = read_bid(auction_id=2, bid_id=1);

    assert 0 = unexistent_stored_bid.amount;
    assert 0 = unexistent_stored_bid.account;
    assert 0 = unexistent_stored_bid.theme_len;

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

    let bid = Bid(account='account', amount=12, theme_len=6, theme=theme);

    %{ expect_revert(error_message="Theme is too long") %}
    assert_bid_valid(auction_id=2, bid=bid);

    return ();
}

@view
func test_validate_bid_amount_too_low{
    syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}() {
    alloc_locals;
    let (theme: felt*) = alloc();
    assert theme[0] = 'My super theme';

    let bid = Bid(account='account', amount=7000000000000000, theme_len=1, theme=theme);

    assert_bid_valid(auction_id=2, bid=bid);
    store_bid(auction_id=2, bid=bid);

    let bid = Bid(account='account', amount=0, theme_len=1, theme=theme);

    %{ expect_revert(error_message="Bid amount must be at least 12000000000000000 since last bid is 7000000000000000") %}
    assert_bid_valid(auction_id=2, bid=bid);

    return ();
}
