%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from starkware.cairo.common.uint256 import Uint256, uint256_le
from starkware.cairo.common.bool import TRUE, FALSE

from openzeppelin.token.erc721.library import ERC721
from openzeppelin.introspection.ERC165 import ERC165

from openzeppelin.access.ownable import Ownable
# TODO => remove ownable?
from openzeppelin.security.safemath import SafeUint256
from openzeppelin.security.initializable import Initializable

#
# Storage
#

@storage_var
func minted_count() -> (count : Uint256):
end

@storage_var
func matrix_size() -> (size : Uint256):
end

@storage_var
func pixel_drawer() -> (address : felt):
end

#
# Constructor
#

@constructor
func constructor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    name : felt, symbol : felt, owner : felt, m_size : Uint256
):
    ERC721.initializer(name, symbol)
    Ownable.initializer(owner)
    matrix_size.write(m_size)
    return ()
end

#
# Getters
#

@view
func supportsInterface{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    interfaceId : felt
) -> (success : felt):
    let (success) = ERC165.supports_interface(interfaceId)
    return (success)
end

@view
func name{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (name : felt):
    let (name) = ERC721.name()
    return (name)
end

@view
func symbol{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (symbol : felt):
    let (symbol) = ERC721.symbol()
    return (symbol)
end

@view
func balanceOf{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(owner : felt) -> (
    balance : Uint256
):
    let (balance : Uint256) = ERC721.balance_of(owner)
    return (balance)
end

@view
func ownerOf{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    tokenId : Uint256
) -> (owner : felt):
    let (owner : felt) = ERC721.owner_of(tokenId)
    return (owner)
end

@view
func getApproved{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    tokenId : Uint256
) -> (approved : felt):
    let (approved : felt) = ERC721.get_approved(tokenId)
    return (approved)
end

@view
func isApprovedForAll{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    owner : felt, operator : felt
) -> (isApproved : felt):
    let (isApproved : felt) = ERC721.is_approved_for_all(owner, operator)
    return (isApproved)
end

@view
func tokenURI{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    tokenId : Uint256
) -> (tokenURI : felt):
    # TODO => fixed tokenURI ?
    let (tokenURI : felt) = ERC721.token_uri(tokenId)
    return (tokenURI)
end

@view
func owner{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (owner : felt):
    let (owner : felt) = Ownable.owner()
    return (owner)
end

@view
func totalSupply{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    count : Uint256
):
    let (count : Uint256) = minted_count.read()
    return (count)
end

@view
func matrixSize{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    count : Uint256
):
    let (count : Uint256) = matrix_size.read()
    return (count)
end

@view
func maxSupply{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    count : Uint256
):
    let (size : Uint256) = matrix_size.read()
    let (count : Uint256) = SafeUint256.mul(size, size)
    return (count=count)
end

@view
func pixelDrawerAddress{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    address : felt
):
    let (address : felt) = pixel_drawer.read()
    return (address=address)
end

#
# Externals
#

@external
func approve{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(
    to : felt, tokenId : Uint256
):
    ERC721.approve(to, tokenId)
    return ()
end

@external
func setApprovalForAll{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    operator : felt, approved : felt
):
    ERC721.set_approval_for_all(operator, approved)
    return ()
end

@external
func transferFrom{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(
    from_ : felt, to : felt, tokenId : Uint256
):
    ERC721.transfer_from(from_, to, tokenId)
    return ()
end

@external
func safeTransferFrom{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(
    from_ : felt, to : felt, tokenId : Uint256, data_len : felt, data : felt*
):
    ERC721.safe_transfer_from(from_, to, tokenId, data_len, data)
    return ()
end

@external
func mint{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(to : felt):
    alloc_locals

    # Ensures no more than PIXEL_COUNT pixels can be minted
    let (local lastTokenId : Uint256) = totalSupply()
    let (local newTokenId : Uint256) = SafeUint256.add(lastTokenId, Uint256(1, 0))
    let (local max : Uint256) = maxSupply()
    let (is_lt) = uint256_le(newTokenId, max)
    with_attr error_message("Total pixel supply has already been minted"):
        assert is_lt = TRUE
    end

    minted_count.write(newTokenId)
    ERC721._mint(to, newTokenId)

    return ()
end

# @external
# func setTokenURI{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(
#     tokenId : Uint256, tokenURI : felt
# ):
#     Ownable.assert_only_owner()
#     ERC721._set_token_uri(tokenId, tokenURI)
#     return ()
# end

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

@external
func initialize{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(
    pixel_drawer_address : felt
):
    Ownable.assert_only_owner()
    let (initialized) = Initializable.initialized()
    with_attr error_message("Pixel contract already initialized"):
        assert initialized = FALSE
    end

    Initializable.initialize()
    pixel_drawer.write(pixel_drawer_address)
    return ()
end
