%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from starkware.cairo.common.uint256 import Uint256, uint256_lt, uint256_eq
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.starknet.common.syscalls import get_caller_address
from starkware.cairo.common.alloc import alloc

from openzeppelin.token.erc721.library import ERC721
from openzeppelin.token.erc721_enumerable.library import ERC721_Enumerable
from openzeppelin.introspection.ERC165 import ERC165

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

#
# Constructor
#

@constructor
func constructor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    name : felt, symbol : felt, owner : felt, m_size : Uint256
):
    ERC721.initializer(name, symbol)
    ERC721_Enumerable.initializer()
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
func totalSupply{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    count : Uint256
):
    let (count : Uint256) = minted_count.read()
    return (count)
end

@view
func matrixSize{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    size : Uint256
):
    let (size : Uint256) = matrix_size.read()
    return (size)
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
func pixelsOfOwner{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    owner : felt
) -> (pixels_len : felt, pixels : felt*):
    alloc_locals
    let (pixels : felt*) = alloc()
    let (balance : Uint256) = ERC721.balance_of(owner)
    get_all_pixels_of_owner(owner, 0, balance.low, pixels)
    return (pixels_len=balance.low, pixels=pixels)
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
    ERC721_Enumerable.transfer_from(from_, to, tokenId)
    return ()
end

@external
func safeTransferFrom{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(
    from_ : felt, to : felt, tokenId : Uint256, data_len : felt, data : felt*
):
    ERC721_Enumerable.safe_transfer_from(from_, to, tokenId, data_len, data)
    return ()
end

@external
func mint{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(to : felt):
    alloc_locals

    # Ensures a pixel holder cannot mint
    let (local balance : Uint256) = balanceOf(to)
    let (local owns_0) = uint256_eq(balance, Uint256(0, 0))

    with_attr error_message("{to} already owns a pixel"):
        assert owns_0 = TRUE
    end

    # Ensures no more than PIXEL_COUNT pixels can be minted
    let (local lastTokenId : Uint256) = totalSupply()
    let (local max : Uint256) = maxSupply()

    let (is_lt) = uint256_lt(lastTokenId, max)
    with_attr error_message("Total pixel supply has already been minted"):
        assert is_lt = TRUE
    end

    let (local newTokenId : Uint256) = SafeUint256.add(lastTokenId, Uint256(1, 0))

    minted_count.write(newTokenId)
    ERC721_Enumerable._mint(to, newTokenId)

    return ()
end

# @external
# func setTokenURI{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(
#     tokenId : Uint256, tokenURI : felt
# ):
#     ERC721._set_token_uri(tokenId, tokenURI)
#     return ()
# end


#
# Helpers
#

func get_all_pixels_of_owner{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    owner : felt, index : felt, balance : felt, pixels : felt*
) -> ():
    if index == balance:
        return ()
    end
    let (tokenId : Uint256) = ERC721_Enumerable.token_of_owner_by_index(
        owner=owner, index=Uint256(low=index, high=0)
    )
    assert pixels[index] = tokenId.low
    return get_all_pixels_of_owner(owner, index + 1, balance, pixels)
end
