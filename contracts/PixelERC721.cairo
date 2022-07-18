%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from starkware.cairo.common.uint256 import Uint256, uint256_lt, uint256_eq
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.starknet.common.syscalls import get_caller_address
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.math_cmp import is_le

from openzeppelin.access.ownable import Ownable
from openzeppelin.token.erc721.library import ERC721
from openzeppelin.token.erc721_enumerable.library import ERC721_Enumerable
from openzeppelin.introspection.ERC165 import ERC165
from openzeppelin.security.safemath import SafeUint256

from contracts.interfaces import IPXLMetadata
from contracts.pxls_metadata.pxls_metadata import get_pxl_json_metadata

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
func contract_uri_hash(index : felt) -> (hash : felt):
end

# The grids with the representation of the 400 PXL NFT
# have been generated off-chain and stored in 4 different
# smart contracts to handle max contract size. From these
# grids, we are able to generate the svg of these PXLS
# and the JSON metadata, fully on-chain!

@storage_var
func pxls_1_100() -> (address : felt):
end

@storage_var
func pxls_101_200() -> (address : felt):
end

@storage_var
func pxls_201_300() -> (address : felt):
end

@storage_var
func pxls_301_400() -> (address : felt):
end

#
# Constructor
#

@constructor
func constructor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    name : felt,
    symbol : felt,
    m_size : Uint256,
    owner : felt,
    pxls_1_100_address : felt,
    pxls_101_200_address : felt,
    pxls_201_300_address : felt,
    pxls_301_400_address : felt,
):
    ERC721.initializer(name, symbol)
    ERC721_Enumerable.initializer()
    Ownable.initializer(owner)
    matrix_size.write(m_size)
    pxls_1_100.write(pxls_1_100_address)
    pxls_101_200.write(pxls_101_200_address)
    pxls_201_300.write(pxls_201_300_address)
    pxls_301_400.write(pxls_301_400_address)
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
func contractURI{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    contractURI_len : felt, contractURI : felt*
):
    # Max length of CID can be stored in 3 short strings
    let (ipfs_hash_0) = contract_uri_hash.read(0)
    let (ipfs_hash_1) = contract_uri_hash.read(1)
    let (ipfs_hash_2) = contract_uri_hash.read(2)
    let (contract_uri : felt*) = alloc()
    assert contract_uri[0] = 'ipfs://'
    assert contract_uri[1] = ipfs_hash_0
    assert contract_uri[2] = ipfs_hash_1
    assert contract_uri[3] = ipfs_hash_2
    return (contractURI_len=4, contractURI=contract_uri)
end

@view
func tokenURI{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    tokenId : Uint256
) -> (tokenURI_len : felt, tokenURI : felt*):
    alloc_locals
    # The tokenURI is an array of felts
    # It's an inline json containing an inline svg, all
    # generated on-chain from grids of data (the colors
    # of each 400 pixels) stored in 4 smart contracts.
    let (pxls_data_addresses : felt*) = alloc()

    let (pxls_1_100_address) = pxls_1_100.read()
    let (pxls_101_200_address) = pxls_101_200.read()
    let (pxls_201_300_address) = pxls_201_300.read()
    let (pxls_301_400_address) = pxls_301_400.read()

    pxls_data_addresses[0] = pxls_1_100_address
    pxls_data_addresses[1] = pxls_101_200_address
    pxls_data_addresses[2] = pxls_201_300_address
    pxls_data_addresses[3] = pxls_301_400_address

    let (less_than_100) = is_le(tokenId.low, 100)
    let (less_than_200) = is_le(tokenId.low, 200)
    let (less_than_300) = is_le(tokenId.low, 300)
    let (less_than_400) = is_le(tokenId.low, 400)

    let contract_index = 4 - less_than_100 - less_than_200 - less_than_300 - less_than_400

    # contract_index is:
    # 0 if 1 <= id <= 100
    # 1 if 101 <= id <= 200
    # 2 if 201 <= id <= 300
    # 3 if 301 <= id <= 400

    let contract_address = pxls_data_addresses[contract_index]

    # Token starts at 1 but pxl index at 0
    let pixel_index = tokenId.low - 1

    # Shifting the index so that we query the metadata array
    # between 0 & 99 for each contract_address
    let shifted_pixel_index = pixel_index - (contract_index * 100)

    let (metadata_len : felt, metadata : felt*) = IPXLMetadata.get_pixel_metadata(
        contract_address=contract_address, pixel_index=shifted_pixel_index
    )
    let (size : Uint256) = matrix_size.read()
    let (pxl_json_metadata_len : felt, pxl_json_metadata : felt*) = get_pxl_json_metadata(
        grid_size=size.low,
        pixel_index=pixel_index,
        pixel_data_len=metadata_len,
        pixel_data=metadata,
    )
    return (tokenURI_len=pxl_json_metadata_len, tokenURI=pxl_json_metadata)
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

@view
func owner{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (owner : felt):
    let (owner : felt) = Ownable.owner()
    return (owner)
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

@external
func setContractURIHash{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(
    hash_len : felt, hash : felt*
):
    Ownable.assert_only_owner()
    contract_uri_hash.write(0, hash[0])
    contract_uri_hash.write(1, hash[1])
    contract_uri_hash.write(2, hash[2])
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
