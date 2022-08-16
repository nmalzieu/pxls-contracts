%lang starknet
from starkware.cairo.common.uint256 import Uint256

#
# Storage
#

# This is the address of the PXL NFT contract (for token gating)
@storage_var
func pixel_erc721() -> (address : felt):
end

# For each rtwrk, we save each user colorization
@storage_var
func drawing_user_colorizations(drawing_round : felt, index : felt) -> (
    user_colorizations_packed : felt
):
end

# For each rtwrk, we save the last colorization index
@storage_var
func drawing_user_colorizations_index(drawing_round : felt) -> (index : felt):
end

# For each token id, we save count of colorizations
@storage_var
func number_of_colorizations_per_token(drawing_round : felt, token_id : Uint256) -> (count : felt):
end

# We also save count of total # of colorizations cause we need to limit due to perf
@storage_var
func number_of_colorizations_total(drawing_round : felt) -> (count : felt):
end

# The max number of colorizations per token / rwtrk is a variable
@storage_var
func max_colorizations_per_token() -> (max : felt):
end

# This saves the start timestamp of an rtwrk
@storage_var
func drawing_timestamp(drawing_round : felt) -> (timestamp : felt):
end

# This returns the current rtwrk round
@storage_var
func current_drawing_round() -> (round : felt):
end

# A flag to tell if anyone can launch
# an rtwrk or only the owner of the contract
@storage_var
func everyone_can_launch_round() -> (bool : felt):
end

# Each round can have a theme that is an array
# of short strings
@storage_var
func drawing_theme(drawing_round : felt, index : felt) -> (short_string : felt):
end
