%lang starknet
from starkware.cairo.common.cairo_builtins import HashBuiltin

from pxls.RtwrkThemeAuction.storage import rtwrk_drawer_address, rtwrk_erc721_address

// @dev The constructor initializing the theme auction contract with important data
// @param rtwrk_drawer_address_value: The address of the Rtwrk Drawer contract
// @param rtwrk_erc721_address_value: The address of the Rtwrk ERC721 contract

@constructor
func constructor{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    rtwrk_drawer_address_value: felt, rtwrk_erc721_address_value: felt
) {
    rtwrk_drawer_address.write(rtwrk_drawer_address_value);
    rtwrk_erc721_address.write(rtwrk_erc721_address_value);

    return ();
}
