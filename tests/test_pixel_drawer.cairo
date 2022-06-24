%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256
from libs.colors import Color, PixelColor
from contracts.interfaces import IPixelERC721, IPixelDrawer

@view
func __setup__{syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*}():
    let name = 'Pixel'
    let symbol = 'PXL'
    let account = 123456

    %{ context.pixel_contract_address = deploy_contract("contracts/PixelERC721.cairo", [ids.name, ids.symbol, ids.account, 20, 0]).contract_address %}
    %{ context.drawer_contract_address = deploy_contract("contracts/PixelDrawer.cairo", [context.pixel_contract_address, ids.account]).contract_address %}

    %{ stop_prank_pixel = start_prank(ids.account, target_contract_address=context.pixel_contract_address) %}
    %{ stop_prank_drawer = start_prank(ids.account, target_contract_address=context.drawer_contract_address) %}

    tempvar pixel_contract_address
    %{ ids.pixel_contract_address = context.pixel_contract_address %}

    tempvar drawer_contract_address
    %{ ids.drawer_contract_address = context.drawer_contract_address %}

    IPixelERC721.initialize(
        contract_address=pixel_contract_address, pixel_drawer_address=drawer_contract_address
    )

    # Warping time before starting the drawer contract
    let start_timestamp = 'start_timestamp'
    %{ warp(ids.start_timestamp, context.drawer_contract_address) %}
    IPixelDrawer.start(contract_address=drawer_contract_address)

    %{ stop_prank_pixel() %}
    %{ stop_prank_drawer() %}
    return ()
end

@view
func test_pixel_drawer_getters{syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*}():
    tempvar pixel_contract_address
    %{ ids.pixel_contract_address = context.pixel_contract_address %}

    tempvar drawer_contract_address
    %{ ids.drawer_contract_address = context.drawer_contract_address %}

    let (p_address) = IPixelDrawer.pixelERC721Address(contract_address=drawer_contract_address)
    assert p_address = pixel_contract_address

    let (d_address) = IPixelERC721.pixelDrawerAddress(contract_address=pixel_contract_address)
    assert d_address = drawer_contract_address

    let (round) = IPixelDrawer.currentDrawingRound()
    assert round = 1

    # Timestamp must have been set to the deployment timestamp

    let (returned_timestamp) = IPixelDrawer.currentDrawingTimestamp(
        contract_address=drawer_contract_address
    )
    assert returned_timestamp = 'start_timestamp'

    return ()
end

@view
func test_pixel_drawer_pixel_owner_nonexistent_token{
    syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*
}():
    tempvar drawer_contract_address
    %{ ids.drawer_contract_address = context.drawer_contract_address %}

    %{ expect_revert(error_message="ERC721: owner query for nonexistent token") %}

    IPixelDrawer.setPixelColor(drawer_contract_address, Uint256(1, 0), Color(255, 0, 100))

    return ()
end

@view
func test_pixel_drawer_pixel_non_token_owner{
    syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*
}():
    tempvar pixel_contract_address
    %{ ids.pixel_contract_address = context.pixel_contract_address %}

    tempvar drawer_contract_address
    %{ ids.drawer_contract_address = context.drawer_contract_address %}

    %{ stop_prank = start_prank(123456, target_contract_address=ids.pixel_contract_address) %}

    # Minting first pixel
    IPixelERC721.mint(contract_address=pixel_contract_address, to=123458)

    # Non owner can't draw pixel
    %{ expect_revert(error_message="Address does not own pixel") %}
    IPixelDrawer.setPixelColor(drawer_contract_address, Uint256(1, 0), Color(255, 0, 100))

    %{ stop_prank() %}
    return ()
end

@view
func test_pixel_drawer_pixel_wrong_color{
    syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*
}():
    tempvar pixel_contract_address
    %{ ids.pixel_contract_address = context.pixel_contract_address %}

    tempvar drawer_contract_address
    %{ ids.drawer_contract_address = context.drawer_contract_address %}

    # Get current color
    let (pixel_color : PixelColor) = IPixelDrawer.pixelColor(drawer_contract_address, Uint256(1, 0))
    assert pixel_color.set = 0  # Unset
    assert pixel_color.color = Color(0, 0, 0)

    %{ stop_prank_drawer = start_prank(123456, target_contract_address=ids.drawer_contract_address) %}

    # Minting first pixel
    IPixelERC721.mint(contract_address=pixel_contract_address, to=123456)

    # Pixel owner cannot draw pixel with wrong color
    %{ expect_revert() %}
    IPixelDrawer.setPixelColor(drawer_contract_address, Uint256(1, 0), Color(265, 0, 100))

    %{ stop_prank_drawer() %}
    return ()
end

@view
func test_pixel_drawer_set_pixel_color{
    syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*
}():
    tempvar pixel_contract_address
    %{ ids.pixel_contract_address = context.pixel_contract_address %}

    tempvar drawer_contract_address
    %{ ids.drawer_contract_address = context.drawer_contract_address %}

    # Get current color
    let (pixel_color : PixelColor) = IPixelDrawer.pixelColor(drawer_contract_address, Uint256(1, 0))
    assert pixel_color.set = 0  # Unset
    assert pixel_color.color = Color(0, 0, 0)

    %{ stop_prank_drawer = start_prank(123456, target_contract_address=ids.drawer_contract_address) %}

    # Minting first pixel
    IPixelERC721.mint(contract_address=pixel_contract_address, to=123456)

    # Pixel owner can draw pixel with right color
    IPixelDrawer.setPixelColor(drawer_contract_address, Uint256(1, 0), Color(255, 0, 100))

    # Check pixel color has been set
    let (pixel_color : PixelColor) = IPixelDrawer.pixelColor(drawer_contract_address, Uint256(1, 0))
    assert pixel_color.set = 1  # Set
    assert pixel_color.color = Color(255, 0, 100)

    # Pixel owner can set pixel color again
    IPixelDrawer.setPixelColor(drawer_contract_address, Uint256(1, 0), Color(100, 23, 190))

    # Check pixel color has been set over
    let (pixel_color : PixelColor) = IPixelDrawer.pixelColor(drawer_contract_address, Uint256(1, 0))
    assert pixel_color.set = 1  # Set
    assert pixel_color.color = Color(100, 23, 190)

    %{ stop_prank_drawer() %}
    return ()
end

@view
func test_pixel_drawer_shuffle_result{
    syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*
}():
    tempvar drawer_contract_address
    %{ ids.drawer_contract_address = context.drawer_contract_address %}

    # Check pixel shuffle
    # For a given matrix size, result is deterministic
    # For 20x20, first token position is 378 = 1 * 373 + 5 % 400
    let (pixel_index_1) = IPixelDrawer.tokenPixelIndex(drawer_contract_address, Uint256(1, 0))
    assert pixel_index_1 = 378
    let (pixel_index_2) = IPixelDrawer.tokenPixelIndex(drawer_contract_address, Uint256(2, 0))
    assert pixel_index_2 = 351
    return ()
end
