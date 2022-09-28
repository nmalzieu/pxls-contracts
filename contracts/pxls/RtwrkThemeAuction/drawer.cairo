%lang starknet
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import get_block_timestamp
from starkware.cairo.common.math_cmp import is_le
from starkware.cairo.common.bool import TRUE, FALSE

from pxls.RtwrkThemeAuction.storage import rtwrk_drawer_address
from pxls.interfaces import IRtwrkDrawer
from pxls.RtwrkThemeAuction.variables import BLOCK_TIME_BUFFER

const DAY_DURATION = 24 * 3600;
const DAY_DURATION_WITH_BUFFER = DAY_DURATION + BLOCK_TIME_BUFFER;

func current_rtwrk_id{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    rtwrk_id: felt
) {
    let (contract_address) = rtwrk_drawer_address.read();
    let (rtwrk_id: felt) = IRtwrkDrawer.currentRtwrkId(contract_address);
    return (rtwrk_id=rtwrk_id);
}

func is_running_rtwrk{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    running_auction: felt
) {
    let (contract_address) = rtwrk_drawer_address.read();
    let (current_id: felt) = current_rtwrk_id();
    let (current_rtwrk_timestamp: felt) = IRtwrkDrawer.rtwrkTimestamp(contract_address, current_id);

    let (block_timestamp) = get_block_timestamp();
    let duration = block_timestamp - current_rtwrk_timestamp;
    // Testing if DAY_DURATION_WITH_BUFFER <= duration
    // so if it's 1, rtwrk has ended
    let rtwrk_ended = is_le(DAY_DURATION_WITH_BUFFER, duration);
    // So we need to return the contrary to check if running auction
    return (running_auction=1 - rtwrk_ended);
}

func assert_running_rtwrk{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    let (running_rtwrk: felt) = is_running_rtwrk();
    with_attr error_message("There is currently no rtwrk running") {
        assert running_rtwrk = TRUE;
    }
    return ();
}

func assert_no_running_rtwrk{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    let (running_rtwrk: felt) = is_running_rtwrk();
    with_attr error_message("Cannot call this method while an rtwrk is running") {
        assert running_rtwrk = FALSE;
    }
    return ();
}

func launch_rtwrk_for_auction{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    theme_len: felt, theme: felt*
) -> (launched_rtwrk_id: felt) {
    alloc_locals;
    let (running_rtwrk: felt) = is_running_rtwrk();
    with_attr error_message("Cannot call this method while an rtwrk is running") {
        assert running_rtwrk = FALSE;
    }
    let (contract_address) = rtwrk_drawer_address.read();
    let (launched) = IRtwrkDrawer.launchNewRtwrkIfNecessary(contract_address, theme_len, theme);

    with_attr error_message("An error occured, the rtwrk could not be launched") {
        assert launched = TRUE;
    }

    let (rtwrk_id) = current_rtwrk_id();
    return (launched_rtwrk_id=rtwrk_id);
}

func rtwrk_colorizers{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    rtwrk_id: felt
) -> (colorizers_len: felt, colorizers: felt*) {
    let (contract_address) = rtwrk_drawer_address.read();
    let (colorizers_len, colorizers: felt*) = IRtwrkDrawer.colorizers(
        contract_address=contract_address, rtwrkId=rtwrk_id, rtwrkStep=0
    );
    return (colorizers_len, colorizers);
}
