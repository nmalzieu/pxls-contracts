%lang starknet
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.uint256 import Uint256

from pxls.RtwrkThemeAuction.storage import rtwrk_erc721_address
from pxls.RtwrkThemeAuction.drawer import current_rtwrk_id
from pxls.interfaces import IRtwrkERC721

func rtwrk_is_minted{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    rtwrk_id: felt
) -> (is_minted: felt) {
    let (contract_address) = rtwrk_erc721_address.read();
    let (is_minted: felt) = IRtwrkERC721.exists(contract_address, Uint256(rtwrk_id, 0));
    return (is_minted=is_minted);
}

func assert_rtwrk_is_minted{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    rtwrk_id: felt
) {
    let (is_minted: felt) = rtwrk_is_minted(rtwrk_id);
    with_attr error_message("Rtwrk {rtwrk_id} has not been minted") {
        assert is_minted = TRUE;
    }
    return ();
}

func assert_rtwrk_is_not_minted{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    rtwrk_id: felt
) {
    let (is_minted: felt) = rtwrk_is_minted(rtwrk_id);
    with_attr error_message("Rtwrk {rtwrk_id} has been minted") {
        assert is_minted = FALSE;
    }
    return ();
}

func assert_current_rtwrk_is_minted{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    ) {
    let (rtwrk_id: felt) = current_rtwrk_id();
    assert_rtwrk_is_minted(rtwrk_id);
    return ();
}
