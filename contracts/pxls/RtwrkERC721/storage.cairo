%lang starknet
from starkware.cairo.common.uint256 import Uint256

@storage_var
func contract_uri_hash(index: felt) -> (hash: felt) {
}

@storage_var
func rtwrk_drawer_address() -> (address: felt) {
}

@storage_var
func rtwrk_theme_auction_address() -> (address: felt) {
}

@storage_var
func rtwrk_chosen_step(rtwrk_id: Uint256) -> (step: felt) {
}