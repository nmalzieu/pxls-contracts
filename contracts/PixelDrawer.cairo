%lang starknet
from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from starkware.cairo.common.uint256 import Uint256, uint256_sub
from starkware.cairo.common.math import unsigned_div_rem
from starkware.cairo.common.math_cmp import is_le
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.starknet.common.syscalls import get_caller_address, get_block_timestamp
from starkware.cairo.common.alloc import alloc

from openzeppelin.access.ownable import Ownable
from openzeppelin.token.erc721.interfaces.IERC721 import IERC721

from libs.colors import Color, PixelColor, assert_valid_color
from contracts.interfaces import IPixelERC721, IPixelDrawerGridData

#
# Storage
#

@storage_var
func pixel_erc721() -> (address : felt):
end

@storage_var
func grids_data() -> (address : felt):
end

@storage_var
func pixel_index_to_pixel_color(drawing_round : felt, pixel_index : felt) -> (color : PixelColor):
end

@storage_var
func drawing_timestamp(drawing_round : felt) -> (timestamp : felt):
end

@storage_var
func current_drawing_round() -> (round : felt):
end

#
# Constructor
#

@constructor
func constructor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    owner : felt, pixel_erc721_address : felt, grids_data_address : felt
):
    Ownable.initializer(owner)
    pixel_erc721.write(pixel_erc721_address)
    grids_data.write(grids_data_address)
    return ()
end

#
# Getters
#

@view
func pixelERC721Address{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    address : felt
):
    let (address : felt) = pixel_erc721.read()
    return (address=address)
end

@view
func gridsDataAddress{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    address : felt
):
    let (address : felt) = grids_data.read()
    return (address=address)
end

@view
func owner{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (owner : felt):
    let (owner : felt) = Ownable.owner()
    return (owner)
end

@view
func currentTokenPixelIndex{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(
    tokenId : Uint256
) -> (pixelIndex : felt):
    let (round) = current_drawing_round.read()
    return tokenPixelIndex(round, tokenId)
end

@view
func tokenPixelIndex{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(
    round : felt, tokenId : Uint256
) -> (pixelIndex : felt):
    let (address : felt) = grids_data.read()
    let (grid_len : felt, grid : felt*) = IPixelDrawerGridData.get_grid_for_round(address, round)
    let pixel_index = grid[tokenId.low - 1] # tokenId starts at 1
    return (pixelIndex=pixel_index)
end

@view
func pixelColor{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(
    tokenId : Uint256
) -> (color : PixelColor):
    let (round) = current_drawing_round.read()
    let (pixel_index) = tokenPixelIndex(round, tokenId)
    let (color) = pixel_index_to_pixel_color.read(round, pixel_index)
    return (color=color)
end

@view
func currentDrawingTimestamp{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(
    ) -> (timestamp : felt):
    let (round) = current_drawing_round.read()
    return drawingTimestamp(round)
end

@view
func drawingTimestamp{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(
    round : felt
) -> (timestamp : felt):
    let (timestamp) = drawing_timestamp.read(round)
    return (timestamp=timestamp)
end

@view
func currentDrawingRound{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}() -> (
    round : felt
):
    let (round) = current_drawing_round.read()
    return (round=round)
end

@view
func pixelIndexToPixelColor{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(
    round : felt, pixelIndex : felt
) -> (color : PixelColor):
    let (color) = pixel_index_to_pixel_color.read(round, pixelIndex)
    return (color=color)
end

@view
func getGrid{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(round : felt) -> (
    grid_len : felt, grid : felt*
):
    alloc_locals
    let (contract_address : felt) = pixel_erc721.read()
    let (max_supply : Uint256) = IPixelERC721.maxSupply(contract_address=contract_address)
    let (local grid : felt*) = alloc()
    let (grid_len : felt) = get_grid(
        round=round, pixel_index=0, max_supply=max_supply.low, grid_len=0, grid=grid
    )
    return (grid_len=grid_len, grid=grid)
end

#
# Helpers
#

func is_pixel_owner{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    address : felt, pixel_id : Uint256
) -> (owns_pixel : felt):
    let (contract_address : felt) = pixel_erc721.read()
    let (owner_address : felt) = IERC721.ownerOf(
        contract_address=contract_address, tokenId=pixel_id
    )
    if owner_address == address:
        return (owns_pixel=TRUE)
    end
    return (owns_pixel=FALSE)
end

func assert_pixel_owner{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    address : felt, pixel_id : Uint256
):
    let (owns_pixel : felt) = is_pixel_owner(address, pixel_id)
    with_attr error_message("Address does not own pixel: address {address}"):
        assert owns_pixel = TRUE
    end
    return ()
end

func should_launch_new_round{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    ) -> (should_launch : felt):
    alloc_locals
    let (block_timestamp) = get_block_timestamp()
    let (last_drawing_timestamp) = currentDrawingTimestamp()
    let duration = block_timestamp - last_drawing_timestamp
    # 1 full day in seconds (get_block_timestamp returns timestamp in seconds)
    const DAY_DURATION = 86400
    # if duration >= DAY_DURATION (last drawing lasted 1 day)
    let (should_launch) = is_le(DAY_DURATION, duration)
    return (should_launch=should_launch)
end

func launch_new_round{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    alloc_locals
    let (current_round) = current_drawing_round.read()
    let new_round = current_round + 1
    let (block_timestamp) = get_block_timestamp()
    drawing_timestamp.write(new_round, block_timestamp)
    current_drawing_round.write(new_round)
    return ()
end

func launch_new_round_if_necessary{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}() -> (launched : felt):
    let (should_launch) = should_launch_new_round()
    if should_launch == TRUE:
        launch_new_round()
        # See https://www.cairo-lang.org/docs/how_cairo_works/builtins.html#revoked-implicit-arguments
        tempvar syscall_ptr = syscall_ptr
        tempvar pedersen_ptr = pedersen_ptr
        tempvar range_check_ptr = range_check_ptr
        return (launched=TRUE)
    else:
        tempvar syscall_ptr = syscall_ptr
        tempvar pedersen_ptr = pedersen_ptr
        tempvar range_check_ptr = range_check_ptr
        return (launched=FALSE)
    end
end

func get_grid{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    round : felt, pixel_index : felt, max_supply : felt, grid_len : felt, grid : felt*
) -> (grid_len : felt):
    if pixel_index == max_supply:
        return (grid_len=grid_len)
    end
    let (pixel_color : PixelColor) = pixel_index_to_pixel_color.read(round, pixel_index)
    assert grid[grid_len] = pixel_color.set
    assert grid[grid_len + 1] = pixel_color.color.red
    assert grid[grid_len + 2] = pixel_color.color.green
    assert grid[grid_len + 3] = pixel_color.color.blue
    return get_grid(
        round=round,
        pixel_index=pixel_index + 1,
        max_supply=max_supply,
        grid_len=grid_len + 4,
        grid=grid,
    )
end

func set_pixel_color{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(
    tokenId : Uint256, color : Color
):
    assert_valid_color(color)

    let (should_launch) = should_launch_new_round()
    with_attr error_message("This drawing round is finished, please launch a new one"):
        assert should_launch = FALSE
    end

    let (caller_address) = get_caller_address()
    assert_pixel_owner(caller_address, tokenId)
    let pixel_color = PixelColor(set=TRUE, color=color)

    let (round) = current_drawing_round.read()
    let (pixel_index) = tokenPixelIndex(round, tokenId)
    pixel_index_to_pixel_color.write(round, pixel_index, pixel_color)
    return ()
end

func set_pixels_colors{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(
    tokenIds_len : felt, tokenIds : Uint256*, colors_len : felt, colors : Color*
):
    if tokenIds_len == 0:
        return ()
    end
    set_pixel_color(tokenIds[0], colors[0])

    return set_pixels_colors(
        tokenIds_len - 1, tokenIds + Uint256.SIZE, colors_len - 1, colors + Color.SIZE
    )
end

#
# Externals
#

@external
func setPixelsColors{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(
    tokenIds_len : felt, tokenIds : Uint256*, colors_len : felt, colors : Color*
):
    with_attr error_message("tokenId and colors array length don't match"):
        assert tokenIds_len = colors_len
    end
    return set_pixels_colors(tokenIds_len, tokenIds, colors_len, colors)
end

@external
func launchNewRoundIfNecessary{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(
    ) -> (launched : felt):
    # Method to just launch a new round with drawing a pixel
    let (launched) = launch_new_round_if_necessary()
    return (launched=launched)
end

@external
func transferOwnership{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    newOwner : felt
):
    Ownable.transfer_ownership(newOwner)
    return ()
end

@external
func renounceOwnership{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    Ownable.renounce_ownership()
    return ()
end
