%lang starknet
from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.starknet.common.syscalls import get_caller_address

# TODO => remove ownable ?
from openzeppelin.access.ownable import Ownable
from openzeppelin.token.erc721.interfaces.IERC721 import IERC721

from libs.colors import Color, assert_valid_color

#
# Struct
#

struct PixelColor:
    # Adding "set" to avoid unset pixels to be considered black
    member set : felt
    member color : Color
end

#
# Storage
#

@storage_var
func pixel_erc721() -> (address : felt):
end

@storage_var
func current_drawing(pixel_index : Uint256) -> (color : PixelColor):
end

#
# Constructor
#

@constructor
func constructor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    pixel_erc721_address : felt, owner : felt
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
func pixelColor{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(
    tokenId : Uint256
) -> (color : PixelColor):
    let (pixel_index) = pixelIndex(tokenId)
    let (color) = current_drawing.read(pixel_index)
    return (color=color)
end

@view
func pixelIndex{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(
    tokenId : Uint256
) -> (pixelIndex : Uint256):
    # Each pixel NFT represents a different
    # pixel in the grid each day
    return (pixelIndex=tokenId)
end

#
# Helpers
#

func is_pixel_owner{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    address : felt, pixel_id : Uint256
) -> (owns_pixel : felt):
    let (contract_address : felt) = pixel_erc721.read()
    let (owner_address : felt) = IERC721.ownerOf(contract_address=contract_address, tokenId=pixel_id)
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

#
# Externals
#

@external
func setPixelColor{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(
    tokenId : Uint256, color : Color
):
    assert_valid_color(color)
    let (caller_address) = get_caller_address()
    assert_pixel_owner(caller_address, tokenId)
    let pixel_color = PixelColor(set=TRUE, color=color)

    let (pixel_index) = pixelIndex(tokenId)
    current_drawing.write(pixel_index, pixel_color)
    return ()
end
