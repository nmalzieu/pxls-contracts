%lang starknet
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.bool import TRUE, FALSE

from openzeppelin.token.erc721.IERC721 import IERC721

from pxls.RtwrkDrawer.storage import pxl_erc721_address

//
// Methods to limit access to PXL NFT owners
//

func is_pxl_owner{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    address: felt, pxl_id: Uint256
) -> (owns_pxl: felt) {
    let (contract_address: felt) = pxl_erc721_address.read();
    let (owner_address: felt) = IERC721.ownerOf(
        contract_address=contract_address, tokenId=pxl_id
    );
    if (owner_address == address) {
        return (owns_pxl=TRUE);
    }
    return (owns_pxl=FALSE);
}

func assert_pxl_owner{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    address: felt, pxl_id: Uint256
) {
    let (owns_pxl: felt) = is_pxl_owner(address, pxl_id);
    with_attr error_message("Address does not own pxl: address {address}") {
        assert owns_pxl = TRUE;
    }
    return ();
}
