%lang starknet
from starkware.cairo.common.uint256 import Uint256

//
// Storage
//

// This is the address of the PXL NFT contract (for token gating)
@storage_var
func pxl_erc721_address() -> (address: felt) {
}

// For each rtwrk, we save each user colorization
@storage_var
func rtwrk_colorizations(rtwrk_id: felt, index: felt) -> (colorization_packed: felt) {
}

// For each rtwrk, we save the last colorization index
@storage_var
func rtwrk_colorization_index(rtwrk_id: felt) -> (index: felt) {
}

// For each token id, we save count of colorizations
@storage_var
func number_of_colorizations_per_colorizer(rtwrk_id: felt, pxl_id: Uint256) -> (count: felt) {
}

// We also save count of total # of colorizations cause we need to limit due to perf
@storage_var
func number_of_colorizations_total(rtwrk_id: felt) -> (count: felt) {
}

// The max number of colorizations per token / rwtrk is a variable
@storage_var
func max_colorizations_per_colorizer() -> (max: felt) {
}

// This saves the start timestamp of an rtwrk
@storage_var
func rtwrk_timestamp(rtwrk_id: felt) -> (timestamp: felt) {
}

// This returns the current rtwrk id
@storage_var
func current_rtwrk_id() -> (rtwrk_id: felt) {
}

// A flag to tell if anyone can launch
// an rtwrk or only the owner of the contract
@storage_var
func everyone_can_launch_rtwrk() -> (bool: felt) {
}

// Each rtwrk can have a theme that is an array
// of short strings
@storage_var
func rtwrk_theme(rtwrk_id: felt, index: felt) -> (short_string: felt) {
}
