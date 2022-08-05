%lang starknet

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
