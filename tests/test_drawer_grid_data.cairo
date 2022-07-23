%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from tests.sample_drawer_grid_data_contract import get_grid_for_round

@view
func test_get_grid_for_round{syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*}():
    let (grid_len : felt, grid : felt*) = get_grid_for_round(1)
    assert 400 = grid_len
    assert 392 = grid[0]
    assert 6 = grid[299]
    assert 111 = grid[399]

    let (grid_len : felt, grid : felt*) = get_grid_for_round(2)
    assert 400 = grid_len
    assert 197 = grid[0]
    assert 375 = grid[299]
    assert 204 = grid[399]

    # Verify that after 100 rounds we go back to initial value
    let (grid_len : felt, grid : felt*) = get_grid_for_round(101)
    assert 400 = grid_len
    assert 392 = grid[0]
    assert 6 = grid[299]
    assert 111 = grid[399]
    return ()
end
