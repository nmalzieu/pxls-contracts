%lang starknet
from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
# TODO => remove ownable ?
from openzeppelin.access.ownable import Ownable

#
# Storage
#

@storage_var
func pixel_erc721() -> (address : felt):
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
