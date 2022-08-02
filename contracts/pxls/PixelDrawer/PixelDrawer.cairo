%lang starknet
from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.bool import FALSE
from starkware.cairo.common.alloc import alloc

from openzeppelin.access.ownable import Ownable

from pxls.utils.colors import Color, PixelColor
from pxls.interfaces import IPixelERC721
from pxls.PixelDrawer.storage import pixel_erc721, current_drawing_round, everyone_can_launch_round
from pxls.PixelDrawer.round import (
    assert_round_exists,
    get_drawing_timestamp,
    assert_current_round_running,
    launch_new_round_if_necessary,
)
from pxls.PixelDrawer.grid import (
    token_pixel_index,
    get_pixel_color_from_pixel_index,
    get_grid,
    set_pixels_colors,
)

#
# Constructor
#

@constructor
func constructor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    owner : felt, pixel_erc721_address : felt
):
    Ownable.initializer(owner)
    pixel_erc721.write(pixel_erc721_address)
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
func owner{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (owner : felt):
    let (owner : felt) = Ownable.owner()
    return (owner)
end

@view
func currentTokenPixelIndex{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(
    tokenId : Uint256
) -> (pixelIndex : felt):
    let (round) = current_drawing_round.read()
    return token_pixel_index(round, tokenId)
end

@view
func tokenPixelIndex{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(
    round : felt, tokenId : Uint256
) -> (pixelIndex : felt):
    assert_round_exists(round)
    return token_pixel_index(round, tokenId)
end

@view
func pixelColor{
    bitwise_ptr : BitwiseBuiltin*, pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr
}(tokenId : Uint256) -> (color : PixelColor):
    alloc_locals
    let (round) = current_drawing_round.read()
    let (pixel_index) = token_pixel_index(round, tokenId)
    let (color) = get_pixel_color_from_pixel_index(round, pixel_index)
    return (color=color)
end

@view
func currentDrawingTimestamp{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(
    ) -> (timestamp : felt):
    let (round) = current_drawing_round.read()
    return get_drawing_timestamp(round)
end

@view
func drawingTimestamp{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(
    round : felt
) -> (timestamp : felt):
    assert_round_exists(round)
    return get_drawing_timestamp(round)
end

@view
func currentDrawingRound{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}() -> (
    round : felt
):
    let (round) = current_drawing_round.read()
    return (round=round)
end

@view
func pixelIndexToPixelColor{
    bitwise_ptr : BitwiseBuiltin*, pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr
}(round : felt, pixelIndex : felt) -> (color : PixelColor):
    let (color) = get_pixel_color_from_pixel_index(round, pixelIndex)
    return (color=color)
end

@view
func getGrid{
    bitwise_ptr : BitwiseBuiltin*, pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr
}(round : felt) -> (grid_len : felt, grid : felt*):
    alloc_locals
    let (contract_address : felt) = pixel_erc721.read()
    let (max_supply : Uint256) = IPixelERC721.maxSupply(contract_address=contract_address)
    let (local grid : felt*) = alloc()
    let (grid_len : felt) = get_grid(
        round=round, pixel_index=0, max_supply=max_supply.low, grid_len=0, grid=grid
    )
    return (grid_len=grid_len, grid=grid)
end

@view
func everyoneCanLaunchRound{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    ) -> (bool : felt):
    let (bool) = everyone_can_launch_round.read()
    return (bool=bool)
end

#
# Externals
#

@external
func setPixelsColors{
    bitwise_ptr : BitwiseBuiltin*, pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr
}(tokenIds_len : felt, tokenIds : Uint256*, colors_len : felt, colors : Color*):
    with_attr error_message("tokenId and colors array length don't match"):
        assert tokenIds_len = colors_len
    end
    assert_current_round_running()
    return set_pixels_colors(tokenIds_len, tokenIds, colors_len, colors)
end

@external
func launchNewRoundIfNecessary{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(
    ) -> (launched : felt):
    alloc_locals
    let (bool) = everyone_can_launch_round.read()
    tempvar syscall_ptr = syscall_ptr
    tempvar pedersen_ptr = pedersen_ptr
    tempvar range_check_ptr = range_check_ptr
    if bool == FALSE:
        Ownable.assert_only_owner()
    end
    # Method to just launch a new round with drawing a pixel
    let (launched) = launch_new_round_if_necessary()
    return (launched=launched)
end

@external
func setEveryoneCanLaunchRound{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(
    bool : felt
):
    Ownable.assert_only_owner()
    everyone_can_launch_round.write(bool)
    return ()
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
