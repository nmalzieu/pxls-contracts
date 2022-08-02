%lang starknet

#
# Storage
#

@storage_var
func pixel_erc721() -> (address : felt):
end

@storage_var
func pixel_index_to_pixel_color(drawing_round : felt, pixel_index : felt) -> (color_packed : felt):
end

@storage_var
func drawing_timestamp(drawing_round : felt) -> (timestamp : felt):
end

@storage_var
func current_drawing_round() -> (round : felt):
end

@storage_var
func everyone_can_launch_round() -> (bool : felt):
end