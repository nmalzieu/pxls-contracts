%lang starknet
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256

from openzeppelin.access.ownable.library import Ownable

from pxls.RtwrkThemeAuction.storage import (
    pxl_erc721_address,
    rtwrk_drawer_address,
    rtwrk_erc721_address,
    current_auction_id,
    auction_timestamp,
    auction_bids_count,
    eth_erc20_address,
    colorizers_balance,
    pxls_balance,
)
from pxls.RtwrkThemeAuction.bid import read_bid, place_bid
from pxls.RtwrkThemeAuction.bid_struct import Bid
from pxls.RtwrkThemeAuction.auction import launch_auction, launch_auction_rtwrk

// @dev The constructor initializing the theme auction contract with important data
// @param rtwrk_drawer_address_value: The address of the Rtwrk Drawer contract
// @param rtwrk_erc721_address_value: The address of the Rtwrk ERC721 contract

@constructor
func constructor{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    owner: felt,
    eth_erc20_address_value: felt,
    pxl_erc721_address_value: felt,
    rtwrk_drawer_address_value: felt,
    rtwrk_erc721_address_value: felt,
) {
    Ownable.initializer(owner);
    eth_erc20_address.write(eth_erc20_address_value);
    pxl_erc721_address.write(pxl_erc721_address_value);
    rtwrk_drawer_address.write(rtwrk_drawer_address_value);
    rtwrk_erc721_address.write(rtwrk_erc721_address_value);

    return ();
}

// ════════════════════════════════════════════════════════════════════════════════════════════════════════════════════
//     @view methods
// ════════════════════════════════════════════════════════════════════════════════════════════════════════════════════

// @notice Get a bid from an auction, from its identifier
// @param auctionId: The id of the auction
// @param bidId: The id of the bid
// @return bidAccount: the account address of the bidder
// @return bidAmount: the amount of the bid
// @return theme: the bid theme as an array of short strings

@view
func bid{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    auctionId: felt, bidId: felt
) -> (
    bidAccount: felt,
    bidAmount: felt,
    bidTimestamp: felt,
    bidReimbursementTimestamp: felt,
    theme_len: felt,
    theme: felt*,
) {
    let (bid: Bid) = read_bid(auctionId, bidId);
    return (
        bidAccount=bid.account,
        bidAmount=bid.amount,
        bidTimestamp=bid.timestamp,
        bidReimbursementTimestamp=bid.reimbursement_timestamp,
        theme_len=bid.theme_len,
        theme=bid.theme,
    );
}

// @notice A getter for the current auction id (even if it is finished)
// @return currentAuctionId: The current auction id

@view
func currentAuctionId{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    currentAuctionId: felt
) {
    let (auction_id) = current_auction_id.read();
    return (currentAuctionId=auction_id);
}

// @notice A getter for the start timestamp of an auction
// @param auctionId: The auction id to get the timestamp of
// @return auctionTimestamp: The current auction id

@view
func auctionTimestamp{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    auctionId
) -> (auctionTimestamp: felt) {
    let (timestamp) = auction_timestamp.read(auctionId);
    return (auctionTimestamp=timestamp);
}

// @notice A getter for the number of bid on a given auction
// @param auction_id: The auction id to get the bids count of
// @return bids_count: The number of bids for this auction id

@view
func auctionBidsCount{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    auctionId: felt
) -> (bidsCount: felt) {
    let (bidsCount) = auction_bids_count.read(auctionId);
    return (bidsCount=bidsCount);
}

// @notice Get the balance of a given colorizer (pxlr)
// @param pxlId: The id of the PXL NFT to get the balance of
// @return balance: The current balance that this PXL NFT can withdraw

@view
func colorizerBalance{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    pxlId: Uint256
) -> (balance: Uint256) {
    let (balance) = colorizers_balance.read(pxlId);
    return (balance=balance);
}

// @notice Get the balance of the pxls project
// @return balance: The current balance that the pxls project owner can withdraw

@view
func pxlsBalance{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    balance: Uint256
) {
    let (balance) = pxls_balance.read();
    return (balance=balance);
}

// @notice Get the owner of this contract (that will be able to withdraw pxls funds)
// @return owner: The current owner of this contract

@view
func owner{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (owner: felt) {
    let (owner: felt) = Ownable.owner();
    return (owner,);
}

// ════════════════════════════════════════════════════════════════════════════════════════════════════════════════════
//     @external methods
// ════════════════════════════════════════════════════════════════════════════════════════════════════════════════════

// @notice A method to launch a new auction (works only if no auction is already running, if no rtwrk is currently
// being drawn, and if the last rtwrk has successfully been minted

@external
func launchAuction{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    launch_auction();
    return ();
}

// @notice Place a bid in the current auction
// @param auctionId: Id of the auction to place bid in. Must be the current running auction.
// @param bidAmount: Amount of the bid. Must be >= last bid amount + bid increment
// @param theme: the bid theme as an array of short strings

@external
func placeBid{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    auctionId, bidAmount: Uint256, theme_len, theme: felt*
) {
    place_bid(auctionId, bidAmount, theme_len, theme);
    return ();
}

// @notice Launch an rtwrk when the auction is finished and it has a winner

@external
func launchAuctionRtwrk{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    launch_auction_rtwrk();
    return ();
}

// @notice Transfer ownership of this contract (change the pxls address that can withdraw)
// @param newOwner: The new owner

@external
func transferOwnership{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    newOwner: felt
) {
    Ownable.transfer_ownership(newOwner);
    return ();
}
