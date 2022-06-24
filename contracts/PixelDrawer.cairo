%lang starknet
from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from starkware.cairo.common.uint256 import Uint256, uint256_sub
from starkware.cairo.common.math import unsigned_div_rem
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.starknet.common.syscalls import get_caller_address, get_block_timestamp

# TODO => remove ownable ?
from openzeppelin.access.ownable import Ownable
from openzeppelin.token.erc721.interfaces.IERC721 import IERC721
from openzeppelin.security.initializable import Initializable

from libs.colors import Color, PixelColor, assert_valid_color

#
# Interfaces
#

@contract_interface
namespace IPixelERC721:
    func maxSupply() -> (count : Uint256):
    end
end

#
# Storage
#

@storage_var
func pixel_erc721() -> (address : felt):
end

@storage_var
func current_drawing(pixel_index : felt) -> (color : PixelColor):
end

@storage_var
func current_token_id_to_pixel_index(token_id : Uint256) -> (pixel_index : felt):
end

@storage_var
func current_drawing_timestamp() -> (timestamp : felt):
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
func tokenPixelIndex{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(
    tokenId : Uint256
) -> (pixelIndex : felt):
    let (pixel_index) = current_token_id_to_pixel_index.read(tokenId)
    return (pixelIndex=pixel_index)
end

@view
func pixelColor{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(
    tokenId : Uint256
) -> (color : PixelColor):
    let (pixel_index) = tokenPixelIndex(tokenId)
    let (color) = current_drawing.read(pixel_index)
    return (color=color)
end

@view
func currentDrawingTimestamp{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(
    ) -> (timestamp : felt):
    let (timestamp) = current_drawing_timestamp.read()
    return (timestamp=timestamp)
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

func get_token_pixel_index_for_shuffle{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}(token_id : Uint256, is_initial_shuffle) -> (index : felt):
    if is_initial_shuffle == TRUE:
        return (token_id.low)
    end
    let (current_index) = current_token_id_to_pixel_index.read(token_id)
    return (current_index)
end

func _shuffle_pixel_position{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    token_id : Uint256, max_supply, is_initial_shuffle
):
    if token_id.low == 0:
        if token_id.high == 0:
            return ()
        end
    end

    # We use the fact that (a x + b) % n will visit all
    # integer values in [0,n) exactly once as x iterates
    # through the integers in [0, n), as long as a is coprime with n.
    # 373 is prime and a good choice for
    # "randomness" for a 20x20 grid : it takes 81 iterations to loop
    # and come back to first position

    let (token_index) = get_token_pixel_index_for_shuffle(token_id, is_initial_shuffle)
    let calculation = 373 * token_index + 5
    let (q, r) = unsigned_div_rem(calculation, max_supply)
    current_token_id_to_pixel_index.write(token_id, r)
    let (next_token_id : Uint256) = uint256_sub(token_id, Uint256(1, 0))
    _shuffle_pixel_position(
        token_id=next_token_id, max_supply=max_supply, is_initial_shuffle=is_initial_shuffle
    )
    return ()
end

func shuffle_pixel_positions{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    is_initial_shuffle
):
    let (contract_address : felt) = pixel_erc721.read()
    let (token_id : Uint256) = IPixelERC721.maxSupply(contract_address=contract_address)

    # We go over all the tokens, and for each one we determine
    # a new position (= pixel index)
    _shuffle_pixel_position(token_id, token_id.low, is_initial_shuffle)
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

    let (pixel_index) = tokenPixelIndex(tokenId)
    current_drawing.write(pixel_index, pixel_color)
    return ()
end

@external
func start{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}():
    Ownable.assert_only_owner()
    let (initialized) = Initializable.initialized()
    with_attr error_message("Drawer contract already started"):
        assert initialized = FALSE
    end

    Initializable.initialize()

    shuffle_pixel_positions(TRUE)
    let (block_timestamp) = get_block_timestamp()
    current_drawing_timestamp.write(block_timestamp)

    return ()
end
