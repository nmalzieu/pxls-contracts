%lang starknet
from starkware.cairo.common.uint256 import Uint256

//
// Storage
//

// This is the address of the ETH ERC 20 contract
@storage_var
func eth_erc20_address() -> (address: felt) {
}

// This is the address of the Rtwrk drawer contract
@storage_var
func rtwrk_drawer_address() -> (address: felt) {
}

// This is the address of the Rtwrk NFT contract
@storage_var
func rtwrk_erc721_address() -> (address: felt) {
}

// Store the last (= current if < 24hours) auction id.
// Starts at 1 (0 = never a single auction launched)
@storage_var
func current_auction_id() -> (auction_id: felt) {
}

// Store the timestamp of the start of an auction
@storage_var
func auction_timestamp(auction_id) -> (timestamp: felt) {
}

// Store the number of bids for a given auction
@storage_var
func auction_bids_count(auction_id) -> (bids_count: felt) {
}

// Store the timestamp when the auction rtwrk was launched
@storage_var
func auction_rtwrk_launch_timestamp(auction_id) -> (timestamp: felt) {
}

// Store the amount of a bid
@storage_var
func bid_amount(auction_id, bid_id) -> (amount: Uint256) {
}

// Store the account that does of a bid
@storage_var
func bid_account(auction_id, bid_id) -> (account: felt) {
}

// Store the timestamp of the bid
@storage_var
func bid_timestamp(auction_id, bid_id) -> (timestamp: felt) {
}

// Store the theme of a bid (may be multiple felts)
@storage_var
func bid_theme(auction_id, bid_id, theme_index) -> (theme_component: felt) {
}

// Store when a bid was reimbursed
@storage_var
func bid_reimbursement_timestamp(auction_id, bid_id) -> (timestamp: felt) {
}
