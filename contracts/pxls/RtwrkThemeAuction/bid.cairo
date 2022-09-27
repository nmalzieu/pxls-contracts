%lang starknet
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.math import assert_le
from starkware.starknet.common.syscalls import get_caller_address, get_contract_address
from starkware.starknet.common.syscalls import get_block_timestamp

from openzeppelin.security.reentrancyguard.library import ReentrancyGuard

from pxls.RtwrkThemeAuction.storage import (
    auction_bids_count,
    bid_amount,
    bid_account,
    bid_theme,
    eth_erc20_address,
    bid_reimbursement_timestamp,
    bid_timestamp,
)
from pxls.RtwrkThemeAuction.variables import THEME_MAX_LENGTH, BID_INCREMENT
from pxls.interfaces import IEthERC20
from pxls.RtwrkThemeAuction.auction import assert_running_auction_id

struct Bid {
    account: felt,
    amount: felt,
    timestamp: felt,
    reimbursement_timestamp: felt,
    theme_len: felt,
    theme: felt*,
}

func store_bid_theme{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    auction_id: felt, bid_id: felt, theme_index: felt, theme_len: felt, theme: felt*
) {
    if (theme_len == 0) {
        return ();
    }
    let theme_component = theme[0];
    bid_theme.write(auction_id, bid_id, theme_index, theme_component);
    return store_bid_theme(auction_id, bid_id, theme_index + 1, theme_len - 1, theme + 1);
}

func read_bid_theme{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    auction_id: felt, bid_id: felt
) -> (theme_len: felt, theme: felt*) {
    alloc_locals;
    let (theme: felt*) = alloc();
    let (theme_len) = _read_bid_theme(auction_id, bid_id, 0, theme);
    return (theme_len, theme);
}

func _read_bid_theme{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    auction_id: felt, bid_id: felt, theme_len: felt, theme: felt*
) -> (theme_len: felt) {
    let (theme_component) = bid_theme.read(auction_id, bid_id, theme_len);
    if (theme_component == 0) {
        return (theme_len,);
    } else {
        assert theme[theme_len] = theme_component;
        return _read_bid_theme(auction_id, bid_id, theme_len + 1, theme);
    }
}

func store_bid{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    auction_id: felt, bid: Bid
) {
    alloc_locals;
    let (bid_id) = auction_bids_count.read(auction_id);
    bid_account.write(auction_id, bid_id, bid.account);
    bid_amount.write(auction_id, bid_id, bid.amount);
    bid_timestamp.write(auction_id, bid_id, bid.timestamp);
    // Not updating the reimbursement timestamp storage even if there is
    // a value here, this is ONLY done in reimburse_bid
    store_bid_theme(auction_id, bid_id, 0, bid.theme_len, bid.theme);
    auction_bids_count.write(auction_id, bid_id + 1);
    return ();
}

func read_bid{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    auction_id: felt, bid_id: felt
) -> (bid: Bid) {
    let (theme_len: felt, theme: felt*) = read_bid_theme(auction_id, bid_id);
    let (account) = bid_account.read(auction_id, bid_id);
    let (amount) = bid_amount.read(auction_id, bid_id);
    let (timestamp) = bid_timestamp.read(auction_id, bid_id);
    let (reimbursement_timestamp) = bid_reimbursement_timestamp.read(auction_id, bid_id);
    let bid = Bid(
        account=account,
        amount=amount,
        timestamp=timestamp,
        reimbursement_timestamp=reimbursement_timestamp,
        theme_len=theme_len,
        theme=theme,
    );
    return (bid=bid);
}

func assert_bid_theme_valid{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    bid: Bid
) -> () {
    with_attr error_message("Theme is too long") {
        assert_le(bid.theme_len, THEME_MAX_LENGTH);
    }
    return ();
}

func assert_bid_amount_valid{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    auction_id: felt, bid: Bid
) -> () {
    alloc_locals;
    // Let's make sure the amount of the bid is more than last bid + increment
    let (last_bid_id) = auction_bids_count.read(auction_id);
    if (last_bid_id == 0) {
        local minimum_new_bid_amount = BID_INCREMENT;
        with_attr error_message(
                "Bid amount must be at least {minimum_new_bid_amount} since last bid is 0") {
            assert_le(minimum_new_bid_amount, bid.amount);
        }
    } else {
        let (local last_bid_amount) = bid_amount.read(auction_id, last_bid_id - 1);
        local minimum_new_bid_amount = last_bid_amount + BID_INCREMENT;
        with_attr error_message(
                "Bid amount must be at least {minimum_new_bid_amount} since last bid is {last_bid_amount}") {
            assert_le(minimum_new_bid_amount, bid.amount);
        }
    }
    return ();
}

func assert_bid_valid{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    auction_id: felt, bid: Bid
) -> () {
    assert_bid_theme_valid(bid);
    assert_bid_amount_valid(auction_id, bid);
    return ();
}

func transfer_amount_from_bidder{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    bid: Bid
) -> () {
    let (auction_contract_address) = get_contract_address();
    let (eth_contract_address) = eth_erc20_address.read();
    // This will fail if the amount hasn't been approved first!
    IEthERC20.transferFrom(
        contract_address=eth_contract_address,
        sender=bid.account,
        recipient=auction_contract_address,
        amount=bid.amount,
    );
    return ();
}

func reimburse_bid{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    auction_id: felt, bid_id: felt
) -> () {
    ReentrancyGuard._start();
    let (reimbursement_timestamp) = bid_reimbursement_timestamp.read(auction_id, bid_id);
    with_attr error_message("Bid {bid_id} has already been reimbursed") {
        assert reimbursement_timestamp = 0;
    }
    let (current_block_timestamp) = get_block_timestamp();
    bid_reimbursement_timestamp.write(auction_id, bid_id, current_block_timestamp);
    let (bid_to_reimburse: Bid) = read_bid(auction_id, bid_id);
    let (eth_contract_address) = eth_erc20_address.read();
    IEthERC20.transfer(
        contract_address=eth_contract_address,
        recipient=bid_to_reimburse.account,
        amount=bid_to_reimburse.amount,
    );
    ReentrancyGuard._end();
    return ();
}

func place_bid{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    auction_id: felt, bid_amount: felt, theme_len: felt, theme: felt*
) -> () {
    alloc_locals;

    // Check that this auction is, indeed, running!
    assert_running_auction_id(auction_id);

    let (caller) = get_caller_address();

    // Check if we already have a bid on this auction
    let (current_bid_count) = auction_bids_count.read(auction_id);

    // Create bid object
    let (current_block_timestamp) = get_block_timestamp();

    let bid = Bid(
        account=caller,
        amount=bid_amount,
        timestamp=current_block_timestamp,
        reimbursement_timestamp=0,
        theme_len=theme_len,
        theme=theme,
    );

    // First validate the bid
    assert_bid_valid(auction_id, bid);

    // Then let's move ETH from bidder's wallet to the smart contract
    transfer_amount_from_bidder(bid);

    // Then save the bid
    store_bid(auction_id, bid);

    // Then in the end, reimburse previous bid
    if (current_bid_count != 0) {
        let last_bid_id = current_bid_count - 1;
        reimburse_bid(auction_id, last_bid_id);
    }
    return ();
}
