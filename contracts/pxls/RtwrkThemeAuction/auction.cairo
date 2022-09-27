%lang starknet
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import get_block_timestamp
from starkware.cairo.common.math_cmp import is_le
from starkware.cairo.common.bool import TRUE
from starkware.cairo.common.math import assert_le, assert_lt

from pxls.RtwrkThemeAuction.auction_checks import assert_no_running_auction, assert_auction_has_bids
from pxls.RtwrkThemeAuction.drawer import (
    assert_no_running_rtwrk,
    launch_rtwrk_for_auction,
    current_rtwrk_id,
)
from pxls.RtwrkThemeAuction.rtwrk_collection import assert_current_rtwrk_is_minted, mint_rtwrk
from pxls.RtwrkThemeAuction.bid import read_bid
from pxls.RtwrkThemeAuction.bid_struct import Bid
from pxls.RtwrkThemeAuction.storage import (
    current_auction_id,
    auction_timestamp,
    auction_rtwrk_launch_timestamp,
    auction_bids_count,
)
from pxls.RtwrkThemeAuction.payment import settle_auction_payments

func launch_auction{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    assert_no_running_auction();
    assert_no_running_rtwrk();
    assert_current_rtwrk_is_minted();
    let (current_id: felt) = current_auction_id.read();
    let new_auction_id = current_id + 1;
    let (block_timestamp) = get_block_timestamp();
    current_auction_id.write(new_auction_id);
    auction_timestamp.write(new_auction_id, block_timestamp);
    return ();
}

func launch_auction_rtwrk{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;
    // Auction must be finished
    assert_no_running_auction();

    // Auction must exist
    let (local auction_id: felt) = current_auction_id.read();

    with_attr error_message("No auction has ever been launched") {
        assert_lt(0, auction_id);
    }

    assert_auction_has_bids(auction_id);

    // Auction rtwrk must not be already launched
    let (local already_launched_timestamp: felt) = auction_rtwrk_launch_timestamp.read(auction_id);
    with_attr error_message(
            "Rtwrk for auction {auction_id} has already been launched at timestamp {already_launched_timestamp}") {
        assert already_launched_timestamp = 0;
    }

    // Mark this auction rtwrk launched
    let (block_timestamp) = get_block_timestamp();
    auction_rtwrk_launch_timestamp.write(auction_id, block_timestamp);

    // Call the Drawer contract to launch the rtwrk!
    let (winning_bid_id) = auction_bids_count.read(auction_id);
    let (winning_bid: Bid) = read_bid(auction_id, winning_bid_id);

    with_attr error_message(
            "An error occured, the winning bid for auction {auction_id} seems to have an empty theme") {
        assert_le(1, winning_bid.theme_len);
    }

    let (launched) = launch_rtwrk_for_auction(winning_bid.theme_len, winning_bid.theme);

    with_attr error_message("An error occured, the rtwrk could not be launched") {
        assert launched = TRUE;
    }

    return ();
}

func settle_auction{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;
    // Auction must be finished
    assert_no_running_auction();
    // Let's get the last auction
    let (local auction_id) = current_auction_id.read();
    // This auction id must be >= 1
    with_attr error_message("No auction has ever been launched") {
        assert_lt(0, auction_id);
    }
    // Verify this auction had bids (if not, user must call launch_auction, not settle_auction)
    assert_auction_has_bids(auction_id);
    // Verify the last auction rtwrk has been launched
    let (local already_launched_timestamp) = auction_rtwrk_launch_timestamp.read(auction_id);
    with_attr error_message(
            "Rtwrk for auction {auction_id} has not yet been launched so auction cannot be settled") {
        assert_lt(0, already_launched_timestamp);
    }
    // Verify the rtwrk has been finished (i.e. no rtwrk is running)
    assert_no_running_rtwrk();
    // Get the winning bid
    let (winning_bid_id) = auction_bids_count.read(auction_id);
    let (winning_bid: Bid) = read_bid(auction_id, winning_bid_id);
    // Let's mint the rtwrk!
    let (rtwrk_id) = current_rtwrk_id();
    mint_rtwrk(winning_bid.account, rtwrk_id);
    // After the current rtwrk is minted, launch a new auction
    launch_auction();
    // And trigger the payments for the rtwrk participants!
    settle_auction_payments(rtwrk_id, winning_bid);
    return ();
}
