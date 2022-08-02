%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from pxls.utils.colors import Color, assert_valid_color_component, assert_valid_color

@view
func test_color_component{syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*}():
    assert_valid_color_component(0)
    assert_valid_color_component(255)
    %{ expect_revert("TRANSACTION_FAILED") %}
    assert_valid_color_component(260)
    return ()
end

@view
func test_color{syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*}():
    assert_valid_color(Color(0, 0, 0))
    assert_valid_color(Color(0, 250, 0))
    %{ expect_revert("TRANSACTION_FAILED") %}
    assert_valid_color(Color(0, 260, 0))
    return ()
end