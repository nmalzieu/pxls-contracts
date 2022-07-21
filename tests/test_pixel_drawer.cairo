%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.bool import TRUE, FALSE

from libs.colors import Color, PixelColor
from contracts.interfaces import IPixelERC721, IPixelDrawer

@view
func __setup__{syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*}():
    let name = 'Pixel'
    let symbol = 'PXL'

    %{ context.account = 123456 %}

    # Data contracts are heavy, deploying just a sample
    %{ context.sample_pxl_metadata_address = deploy_contract("tests/sample_pxl_metadata_contract.cairo", []).contract_address %}

    %{
        context.pixel_contract_address = deploy_contract("contracts/PixelERC721.cairo", [
            ids.name,
            ids.symbol,
            20,
            0,
            context.account,
            context.sample_pxl_metadata_address,
            context.sample_pxl_metadata_address,
            context.sample_pxl_metadata_address,
            context.sample_pxl_metadata_address
        ]).contract_address
    %}
    %{ context.drawer_contract_address = deploy_contract("contracts/PixelDrawer.cairo", [context.account, context.pixel_contract_address]).contract_address %}

    %{ stop_prank_pixel = start_prank(context.account, target_contract_address=context.pixel_contract_address) %}
    %{ stop_prank_drawer = start_prank(context.account, target_contract_address=context.drawer_contract_address) %}

    tempvar pixel_contract_address
    %{ ids.pixel_contract_address = context.pixel_contract_address %}

    tempvar drawer_contract_address
    %{ ids.drawer_contract_address = context.drawer_contract_address %}

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

    let (round) = IPixelDrawer.currentDrawingRound(contract_address=drawer_contract_address)
    assert round = 1

    let (owner : felt) = IPixelDrawer.owner(contract_address=pixel_contract_address)
    assert 123456 = owner

    # Timestamp must have been set to the deployment timestamp

    let (returned_timestamp) = IPixelDrawer.currentDrawingTimestamp(
        contract_address=drawer_contract_address
    )
    assert returned_timestamp = 'start_timestamp'

    return ()
end

@view
func test_pixel_drawer_transfer_ownership{
    syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*
}():
    tempvar drawer_contract_address
    %{ ids.drawer_contract_address = context.drawer_contract_address %}
    let (owner : felt) = IPixelDrawer.owner(contract_address=drawer_contract_address)
    assert 123456 = owner

    %{ stop_prank = start_prank(123456, target_contract_address=ids.drawer_contract_address) %}
    IPixelDrawer.transferOwnership(drawer_contract_address, 123457)
    %{ stop_prank() %}

    let (owner : felt) = IPixelDrawer.owner(contract_address=drawer_contract_address)
    assert 123457 = owner

    %{ expect_revert(error_message="Ownable: caller is not the owner") %}
    IPixelDrawer.transferOwnership(drawer_contract_address, 123457)

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

    %{ stop_prank = start_prank(context.account, target_contract_address=ids.pixel_contract_address) %}

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

    %{ stop_prank_drawer = start_prank(context.account, target_contract_address=ids.drawer_contract_address) %}

    tempvar account
    %{ ids.account = context.account %}

    # Minting first pixel
    IPixelERC721.mint(contract_address=pixel_contract_address, to=account)

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

    %{ stop_prank_drawer = start_prank(context.account, target_contract_address=ids.drawer_contract_address) %}

    tempvar account
    %{ ids.account = context.account %}

    # Minting first pixel
    IPixelERC721.mint(contract_address=pixel_contract_address, to=account)

    # Pixel owner can draw pixel with right color
    IPixelDrawer.setPixelColor(drawer_contract_address, Uint256(1, 0), Color(255, 0, 100))

    # Check pixel color has been set
    let (pixel_color : PixelColor) = IPixelDrawer.pixelColor(drawer_contract_address, Uint256(1, 0))
    assert pixel_color.set = TRUE  # Set
    assert pixel_color.color = Color(255, 0, 100)

    # Pixel owner can set pixel color again
    IPixelDrawer.setPixelColor(drawer_contract_address, Uint256(1, 0), Color(100, 23, 190))

    # Check pixel color has been set over
    let (pixel_color : PixelColor) = IPixelDrawer.pixelColor(drawer_contract_address, Uint256(1, 0))
    assert pixel_color.set = TRUE  # Set
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
    # last token position is 5 = 400 * 373 + 5 % 400
    let (pixel_index_first) = IPixelDrawer.tokenPixelIndex(drawer_contract_address, Uint256(1, 0))
    assert pixel_index_first = 378
    let (pixel_index_last) = IPixelDrawer.tokenPixelIndex(drawer_contract_address, Uint256(400, 0))
    assert pixel_index_last = 5
    return ()
end

@view
func test_pixel_launch_new_round_if_necessary{
    syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*
}():
    tempvar drawer_contract_address
    %{ ids.drawer_contract_address = context.drawer_contract_address %}

    # after calling start() in setup, we're at round 1

    let (round) = IPixelDrawer.currentDrawingRound(contract_address=drawer_contract_address)
    assert round = 1

    # 23 hour is not enough to launch new round

    let new_timestamp = 'start_timestamp' + (23 * 3600)
    %{ warp(ids.new_timestamp, context.drawer_contract_address) %}

    let (launched) = IPixelDrawer.launchNewRoundIfNecessary(
        contract_address=drawer_contract_address
    )
    assert launched = FALSE

    let (round) = IPixelDrawer.currentDrawingRound(contract_address=drawer_contract_address)
    assert round = 1

    # 25 hour is enough to launch new round

    let new_timestamp = 'start_timestamp' + (25 * 3600)
    %{ warp(ids.new_timestamp, context.drawer_contract_address) %}

    let (launched) = IPixelDrawer.launchNewRoundIfNecessary(
        contract_address=drawer_contract_address
    )
    assert launched = TRUE

    let (round) = IPixelDrawer.currentDrawingRound(contract_address=drawer_contract_address)
    assert round = 2

    # When a new round is launched, the pixel repartition is shuffled

    let (pixel_index_first) = IPixelDrawer.tokenPixelIndex(drawer_contract_address, Uint256(1, 0))
    assert pixel_index_first = 199
    let (pixel_index_last) = IPixelDrawer.tokenPixelIndex(drawer_contract_address, Uint256(400, 0))
    assert pixel_index_last = 270

    return ()
end

@view
func test_pixel_drawing_fails_if_old_round{
    syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*
}():
    tempvar pixel_contract_address
    %{ ids.pixel_contract_address = context.pixel_contract_address %}

    tempvar drawer_contract_address
    %{ ids.drawer_contract_address = context.drawer_contract_address %}

    # after calling start() in setup, we're at round 1

    let (round) = IPixelDrawer.currentDrawingRound(contract_address=drawer_contract_address)
    assert round = 1

    tempvar account
    %{ ids.account = context.account %}

    %{ stop_prank_drawer = start_prank(context.account, target_contract_address=ids.drawer_contract_address) %}

    # Minting first pixel
    IPixelERC721.mint(contract_address=pixel_contract_address, to=account)

    # Pixel owner can draw pixel
    IPixelDrawer.setPixelColor(drawer_contract_address, Uint256(1, 0), Color(255, 0, 100))

    # 23 hour is not enough to launch new round

    let new_timestamp = 'start_timestamp' + (23 * 3600)
    %{ warp(ids.new_timestamp, context.drawer_contract_address) %}

    # Drawing pixel after < 1 day does not launch new round
    IPixelDrawer.setPixelColor(drawer_contract_address, Uint256(1, 0), Color(255, 0, 100))

    let (round) = IPixelDrawer.currentDrawingRound(contract_address=drawer_contract_address)
    assert round = 1

    # 25 hour is enough to launch new round

    let new_timestamp = 'start_timestamp' + (25 * 3600)
    %{ warp(ids.new_timestamp, context.drawer_contract_address) %}

    # Drawing pixel after 1 day fails if no new round has been launched
    %{ expect_revert(error_message="This drawing round is finished, please launch a new one") %}
    IPixelDrawer.setPixelColor(drawer_contract_address, Uint256(1, 0), Color(255, 0, 100))

    %{ stop_prank_drawer() %}

    return ()
end

@view
func test_pixel_index_to_pixel_color_with_rounds{
    syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*
}():
    tempvar pixel_contract_address
    %{ ids.pixel_contract_address = context.pixel_contract_address %}

    tempvar drawer_contract_address
    %{ ids.drawer_contract_address = context.drawer_contract_address %}

    # after calling start() in setup, we're at round 1

    let (round) = IPixelDrawer.currentDrawingRound(contract_address=drawer_contract_address)
    assert round = 1

    tempvar account
    %{ ids.account = context.account %}

    %{ stop_prank_drawer = start_prank(context.account, target_contract_address=ids.drawer_contract_address) %}

    # Minting first pixel
    IPixelERC721.mint(contract_address=pixel_contract_address, to=account)

    # Pixel owner can draw pixel
    IPixelDrawer.setPixelColor(drawer_contract_address, Uint256(1, 0), Color(255, 0, 100))

    # 25 hour is enough to launch new round

    let new_timestamp = 'start_timestamp' + (25 * 3600)
    %{ warp(ids.new_timestamp, context.drawer_contract_address) %}

    # Launch new round

    IPixelDrawer.launchNewRoundIfNecessary(contract_address=drawer_contract_address)

    let (round) = IPixelDrawer.currentDrawingRound(contract_address=drawer_contract_address)
    assert round = 2

    # Drawing pixel after launching new round
    IPixelDrawer.setPixelColor(drawer_contract_address, Uint256(1, 0), Color(123, 200, 0))

    %{ stop_prank_drawer() %}

    # We know pixel #1 position is 378 for round 1, then 199 for round 2
    # let's check if pixel color history is well saved in the state

    let (round_1_color : PixelColor) = IPixelDrawer.pixelIndexToPixelColor(
        contract_address=drawer_contract_address, round=1, pixelIndex=378
    )
    let (round_2_color : PixelColor) = IPixelDrawer.pixelIndexToPixelColor(
        contract_address=drawer_contract_address, round=2, pixelIndex=199
    )

    assert round_1_color.set = TRUE
    assert round_1_color.color = Color(255, 0, 100)

    assert round_2_color.set = TRUE
    assert round_2_color.color = Color(123, 200, 0)

    return ()
end

@view
func test_pixel_get_grid{syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*}():
    tempvar pixel_contract_address
    %{ ids.pixel_contract_address = context.pixel_contract_address %}

    tempvar drawer_contract_address
    %{ ids.drawer_contract_address = context.drawer_contract_address %}

    # after calling start() in setup, we're at round 1

    let (round) = IPixelDrawer.currentDrawingRound(contract_address=drawer_contract_address)
    assert round = 1

    tempvar account
    %{ ids.account = context.account %}

    %{ stop_prank_drawer = start_prank(context.account, target_contract_address=ids.drawer_contract_address) %}

    # Minting first pixel
    IPixelERC721.mint(contract_address=pixel_contract_address, to=account)

    # Pixel owner can draw pixel
    IPixelDrawer.setPixelColor(drawer_contract_address, Uint256(1, 0), Color(255, 0, 100))

    # 25 hour is enough to launch new round

    let new_timestamp = 'start_timestamp' + (25 * 3600)
    %{ warp(ids.new_timestamp, context.drawer_contract_address) %}

    # Launch new round

    IPixelDrawer.launchNewRoundIfNecessary(contract_address=drawer_contract_address)

    let (round) = IPixelDrawer.currentDrawingRound(contract_address=drawer_contract_address)
    assert round = 2

    # Drawing pixel after launching new round
    IPixelDrawer.setPixelColor(drawer_contract_address, Uint256(1, 0), Color(123, 200, 0))

    %{ stop_prank_drawer() %}

    # We know pixel #1 position is 378 for round 1, then 199 for round 2
    # let's check if pixel color history is well saved in the state

    let (grid_1_len : felt, grid_1 : felt*) = IPixelDrawer.getGrid(
        contract_address=drawer_contract_address, round=1
    )
    let (grid_2_len : felt, grid_2 : felt*) = IPixelDrawer.getGrid(
        contract_address=drawer_contract_address, round=2
    )

    # Length is # of pixel * 4 (see PixelColor struct)
    assert 20 * 20 * 4 = grid_1_len
    assert 20 * 20 * 4 = grid_2_len

    # Pixel 378 of round 1 set to 255, 0, 100

    assert TRUE = grid_1[378 * 4]
    assert 255 = grid_1[378 * 4 + 1]
    assert 0 = grid_1[378 * 4 + 2]
    assert 100 = grid_1[378 * 4 + 3]

    # Pixel 199 of round 2 set to 123, 200, 0

    assert TRUE = grid_2[199 * 4]
    assert 123 = grid_2[199 * 4 + 1]
    assert 200 = grid_2[199 * 4 + 2]
    assert 0 = grid_2[199 * 4 + 3]

    return ()
end
