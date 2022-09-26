%lang starknet
from starkware.cairo.common.cairo_builtins import HashBuiltin

from pxls.RtwrkThemeAuction.storage import rtwrk_drawer_address
from pxls.interfaces import IRtwrkDrawer

func current_rtwrk_id{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    rtwrk_id: felt
) {
    let (contract_address) = rtwrk_drawer_address.read();
    let (rtwrk_id: felt) = IRtwrkDrawer.currentRtwrkId(contract_address);
    return (rtwrk_id=rtwrk_id);
}
