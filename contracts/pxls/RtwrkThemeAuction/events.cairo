%lang starknet
from starkware.cairo.common.uint256 import Uint256
from pxls.RtwrkDrawer.colorization import PixelColorization

@event
func auction_launched(caller_account_address: felt, auction_id: felt) {
}

@event
func rtwrk_launched(
    caller_account_address: felt, auction_id: felt, rtwrk_id: felt, theme_len: felt, theme: felt*
) {
}

@event
func auction_settled(
    caller_account_address: felt, winner_account_address: felt, auction_id: felt, rtwrk_id: felt
) {
}

@event
func bid_placed(
    auction_id: felt, caller_account_address: felt, amount: Uint256, theme_len: felt, theme: felt*
) {
}

@event
func pxls_balance_withdrawn(caller_account_address: felt, amount: Uint256, recipient: felt) {
}

@event
func colorizer_balance_withdrawn(
    caller_account_address: felt, amount: Uint256, pxl_id: Uint256, recipient: felt
) {
}
