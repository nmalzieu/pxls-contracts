%lang starknet
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256

from pxls.RtwrkERC721.storage import rtwrk_drawer_address, rtwrk_chosen_step
from pxls.interfaces import IRtwrkDrawer

func rtwrk_steps_count{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    rtwrk_id: Uint256
) -> (steps: felt) {
    let (contract_address) = rtwrk_drawer_address.read();
    let (steps) = IRtwrkDrawer.rtwrkStepsCount(contract_address, rtwrk_id.low);
    return (steps=steps);
}

func rtwrk_token_uri{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    rtwrk_id: Uint256
) -> (token_uri_len: felt, token_uri: felt*) {
    let (contract_address) = rtwrk_drawer_address.read();
    let (step) = rtwrk_chosen_step.read(rtwrk_id);
    let (token_uri_len, token_uri: felt*) = IRtwrkDrawer.rtwrkTokenUri(
        contract_address, rtwrk_id.low, step
    );
    return (token_uri_len, token_uri);
}
