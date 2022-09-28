%lang starknet
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.uint256 import Uint256

from pxls.RtwrkThemeAuction.storage import pxls_erc721_address
from pxls.interfaces import IPxlERC721

func get_current_owner_of_pxl{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    pxl_id: Uint256
) -> (owner: felt) {
    let (contract_address) = pxls_erc721_address.read();
    let (owner: felt) = IPxlERC721.ownerOf(contract_address=contract_address, tokenId=pxl_id);
    return (owner=owner);
}
