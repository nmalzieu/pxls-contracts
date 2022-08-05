%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.alloc import alloc

from pxls.utils.colors import Color, PixelColor
from pxls.PixelDrawer.colorization import Colorization
from pxls.interfaces import IPixelERC721, IPixelDrawer

@view
func __setup__{syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*}():
    let name = 'Pixel'
    let symbol = 'PXL'

    %{ context.account = 123456 %}

    # Data contracts are heavy, deploying just a sample
    %{ context.sample_pxl_metadata_address = deploy_contract("tests/sample_pxl_metadata_contract.cairo", []).contract_address %}

    %{
        context.pixel_contract_address = deploy_contract("contracts/pxls/PixelERC721/PixelERC721.cairo", [
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
    %{ context.drawer_contract_address = deploy_contract("contracts/pxls/PixelDrawer/PixelDrawer.cairo", [context.account, context.pixel_contract_address, 5]).contract_address %}

    %{ stop_prank_pixel = start_prank(context.account, target_contract_address=context.pixel_contract_address) %}
    %{ stop_prank_drawer = start_prank(context.account, target_contract_address=context.drawer_contract_address) %}

    tempvar pixel_contract_address
    %{ ids.pixel_contract_address = context.pixel_contract_address %}

    tempvar drawer_contract_address
    %{ ids.drawer_contract_address = context.drawer_contract_address %}

    # Warping time before launching the initial round
    let start_timestamp = 'start_timestamp'
    %{ warp(ids.start_timestamp, context.drawer_contract_address) %}
    # Launching the initial round
    IPixelDrawer.launchNewRoundIfNecessary(contract_address=drawer_contract_address)

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

    let (owner : felt) = IPixelDrawer.owner(contract_address=drawer_contract_address)
    assert 123456 = owner

    let (bool : felt) = IPixelDrawer.everyoneCanLaunchRound(
        contract_address=drawer_contract_address
    )
    assert FALSE = bool

    # Timestamp must have been set to the deployment timestamp

    let (returned_timestamp) = IPixelDrawer.currentDrawingTimestamp(
        contract_address=drawer_contract_address
    )
    assert returned_timestamp = 'start_timestamp'

    # Max has been set during deploy also
    let (max) = IPixelDrawer.maxColorizationsPerToken(drawer_contract_address)
    assert 5 = max

    return ()
end

@view
func test_pixel_drawer_max_colorizations_update{
    syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*
}():
    tempvar drawer_contract_address
    %{ ids.drawer_contract_address = context.drawer_contract_address %}

    %{ stop_prank = start_prank(context.account, target_contract_address=ids.drawer_contract_address) %}

    IPixelDrawer.setMaxColorizationsPerToken(drawer_contract_address, 10)

    # Max has been set during deploy also
    let (new_max) = IPixelDrawer.maxColorizationsPerToken(drawer_contract_address)
    assert 10 = new_max

    %{ stop_prank() %}

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

    # Nobody owns pxl 1 so it should fail

    let (colorizations : Colorization*) = alloc()
    assert colorizations[0] = Colorization(pixel_index=12, color_index=3)

    IPixelDrawer.colorizePixels(drawer_contract_address, Uint256(1, 0), 1, colorizations)

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

    let (colorizations : Colorization*) = alloc()
    assert colorizations[0] = Colorization(pixel_index=12, color_index=3)

    IPixelDrawer.colorizePixels(drawer_contract_address, Uint256(1, 0), 1, colorizations)

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
    let (pixel_color : PixelColor) = IPixelDrawer.currentDrawingPixelColor(
        drawer_contract_address, 12
    )
    assert pixel_color.set = 0  # Unset
    assert pixel_color.color = Color(0, 0, 0)

    %{ stop_prank_drawer = start_prank(context.account, target_contract_address=ids.drawer_contract_address) %}

    tempvar account
    %{ ids.account = context.account %}

    # Minting first pixel
    IPixelERC721.mint(contract_address=pixel_contract_address, to=account)

    # Pixel owner cannot draw pixel with wrong color
    %{ expect_revert(error_message="Color index is out of bounds") %}
    let (colorizations : Colorization*) = alloc()
    assert colorizations[0] = Colorization(pixel_index=12, color_index=95)

    IPixelDrawer.colorizePixels(drawer_contract_address, Uint256(1, 0), 1, colorizations)

    %{ stop_prank_drawer() %}
    return ()
end

@view
func test_pixel_drawer_colorize_pixels{
    syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*
}():
    alloc_locals
    local pixel_contract_address
    %{ ids.pixel_contract_address = context.pixel_contract_address %}

    local drawer_contract_address
    %{ ids.drawer_contract_address = context.drawer_contract_address %}

    # Get current colors
    let (pixel_1_color : PixelColor) = IPixelDrawer.currentDrawingPixelColor(
        drawer_contract_address, 12
    )
    assert 0 = pixel_1_color.set  # Unset
    assert Color(0, 0, 0) = pixel_1_color.color

    let (pixel_2_color : PixelColor) = IPixelDrawer.currentDrawingPixelColor(
        drawer_contract_address, 300
    )
    assert 0 = pixel_2_color.set  # Unset
    assert Color(0, 0, 0) = pixel_2_color.color

    %{ stop_prank_drawer = start_prank(context.account, target_contract_address=ids.drawer_contract_address) %}

    local account
    %{ ids.account = context.account %}

    # Minting first pixel
    IPixelERC721.mint(contract_address=pixel_contract_address, to=account)

    # Pixel owner can draw multiple pixels with right colors

    let (colorizations : Colorization*) = alloc()
    assert colorizations[0] = Colorization(pixel_index=12, color_index=93)
    assert colorizations[1] = Colorization(pixel_index=300, color_index=2)

    IPixelDrawer.colorizePixels(drawer_contract_address, Uint256(1, 0), 2, colorizations)

    # Check pixel colors have been set
    let (pixel_1_color : PixelColor) = IPixelDrawer.currentDrawingPixelColor(
        drawer_contract_address, 12
    )
    assert TRUE = pixel_1_color.set  # Set
    assert Color(217, 217, 217) = pixel_1_color.color
    let (pixel_2_color : PixelColor) = IPixelDrawer.currentDrawingPixelColor(
        drawer_contract_address, 300
    )
    assert TRUE = pixel_2_color.set  # Set
    assert Color(244, 67, 54) = pixel_2_color.color

    %{ stop_prank_drawer() %}
    return ()
end

@view
func test_pixel_launch_new_round_if_necessary{
    syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*
}():
    tempvar drawer_contract_address
    %{ ids.drawer_contract_address = context.drawer_contract_address %}

    %{ stop_prank_drawer = start_prank(context.account, target_contract_address=ids.drawer_contract_address) %}

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

    # 24+ hour is enough to launch new round

    let new_timestamp = 'start_timestamp' + (24 * 3600 + 136)
    %{ warp(ids.new_timestamp, context.drawer_contract_address) %}

    let (launched) = IPixelDrawer.launchNewRoundIfNecessary(
        contract_address=drawer_contract_address
    )
    assert launched = TRUE

    let (round) = IPixelDrawer.currentDrawingRound(contract_address=drawer_contract_address)
    assert round = 2

    let (current_timestamp) = IPixelDrawer.currentDrawingTimestamp(
        contract_address=drawer_contract_address
    )
    assert new_timestamp = current_timestamp

    let (previous_timestamp) = IPixelDrawer.drawingTimestamp(
        contract_address=drawer_contract_address, round=1
    )
    assert 'start_timestamp' = previous_timestamp

    %{ stop_prank_drawer() %}

    return ()
end

@view
func test_pixel_drawing_fails_if_old_round{
    syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*
}():
    alloc_locals
    local pixel_contract_address
    %{ ids.pixel_contract_address = context.pixel_contract_address %}

    local drawer_contract_address
    %{ ids.drawer_contract_address = context.drawer_contract_address %}

    # after calling start() in setup, we're at round 1

    let (round) = IPixelDrawer.currentDrawingRound(contract_address=drawer_contract_address)
    assert round = 1

    local account
    %{ ids.account = context.account %}

    %{ stop_prank_drawer = start_prank(context.account, target_contract_address=ids.drawer_contract_address) %}

    # Minting first pixel
    IPixelERC721.mint(contract_address=pixel_contract_address, to=account)

    # Pixel owner can draw pixel
    let (colorizations : Colorization*) = alloc()
    assert colorizations[0] = Colorization(pixel_index=12, color_index=3)

    IPixelDrawer.colorizePixels(drawer_contract_address, Uint256(1, 0), 1, colorizations)

    # 23 hour is not enough to launch new round

    let new_timestamp = 'start_timestamp' + (23 * 3600)
    %{ warp(ids.new_timestamp, context.drawer_contract_address) %}

    # Drawing pixel after < 1 day does not launch new round
    IPixelDrawer.colorizePixels(drawer_contract_address, Uint256(1, 0), 1, colorizations)

    let (round) = IPixelDrawer.currentDrawingRound(contract_address=drawer_contract_address)
    assert round = 1

    # 24+ hour is enough to launch new round

    let new_timestamp = 'start_timestamp' + (24 * 3600 + 136)
    %{ warp(ids.new_timestamp, context.drawer_contract_address) %}

    # Drawing pixel after 1 day fails if no new round has been launched
    %{ expect_revert(error_message="This drawing round is finished, please launch a new one") %}
    IPixelDrawer.colorizePixels(drawer_contract_address, Uint256(1, 0), 1, colorizations)

    %{ stop_prank_drawer() %}

    return ()
end

@view
func test_pixel_get_grid{syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*}():
    alloc_locals
    local pixel_contract_address
    %{ ids.pixel_contract_address = context.pixel_contract_address %}

    local drawer_contract_address
    %{ ids.drawer_contract_address = context.drawer_contract_address %}

    # after calling start() in setup, we're at round 1

    let (round) = IPixelDrawer.currentDrawingRound(contract_address=drawer_contract_address)
    assert round = 1

    local account
    %{ ids.account = context.account %}

    %{ stop_prank_drawer = start_prank(context.account, target_contract_address=ids.drawer_contract_address) %}

    # Minting first pixel
    IPixelERC721.mint(contract_address=pixel_contract_address, to=account)

    # Pixel owner can draw pixel
    let (colorizations : Colorization*) = alloc()
    assert colorizations[0] = Colorization(pixel_index=12, color_index=3)

    IPixelDrawer.colorizePixels(drawer_contract_address, Uint256(1, 0), 1, colorizations)

    # 24+ hour is enough to launch new round

    let new_timestamp = 'start_timestamp' + (24 * 3600 + 136)
    %{ warp(ids.new_timestamp, context.drawer_contract_address) %}

    # Launch new round

    IPixelDrawer.launchNewRoundIfNecessary(contract_address=drawer_contract_address)

    let (round) = IPixelDrawer.currentDrawingRound(contract_address=drawer_contract_address)
    assert round = 2

    # Drawing pixel after launching new round
    let (colorizations : Colorization*) = alloc()
    assert colorizations[0] = Colorization(pixel_index=18, color_index=63)

    IPixelDrawer.colorizePixels(drawer_contract_address, Uint256(1, 0), 1, colorizations)

    %{ stop_prank_drawer() %}

    let (grid_1_len : felt, grid_1 : felt*) = IPixelDrawer.getGrid(
        contract_address=drawer_contract_address, round=1
    )
    let (grid_2_len : felt, grid_2 : felt*) = IPixelDrawer.getGrid(
        contract_address=drawer_contract_address, round=2
    )

    # Length is # of pixel * 4 (see PixelColor struct)
    assert 20 * 20 * 4 = grid_1_len
    assert 20 * 20 * 4 = grid_2_len

    # Pixel 12 of round 1 set to color 3 = 229	115	115

    assert TRUE = grid_1[12 * 4]
    assert 229 = grid_1[12 * 4 + 1]
    assert 115 = grid_1[12 * 4 + 2]
    assert 115 = grid_1[12 * 4 + 3]

    # Pixel 18 of round 2 set to color 64 = 255	241	118

    assert TRUE = grid_2[18 * 4]
    assert 255 = grid_2[18 * 4 + 1]
    assert 241 = grid_2[18 * 4 + 2]
    assert 118 = grid_2[18 * 4 + 3]

    return ()
end

@view
func test_pixel_owner_can_change_launch_flag{
    syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*
}():
    tempvar drawer_contract_address
    %{ ids.drawer_contract_address = context.drawer_contract_address %}

    let (bool : felt) = IPixelDrawer.everyoneCanLaunchRound(
        contract_address=drawer_contract_address
    )
    assert FALSE = bool

    # Check that owner can, indeed, modify the flag
    %{ stop_prank_drawer = start_prank(context.account, target_contract_address=ids.drawer_contract_address) %}
    IPixelDrawer.setEveryoneCanLaunchRound(contract_address=drawer_contract_address, bool=TRUE)

    let (bool : felt) = IPixelDrawer.everyoneCanLaunchRound(
        contract_address=drawer_contract_address
    )
    assert TRUE = bool

    %{ stop_prank_drawer() %}

    # Check that non owner cannot update flag
    %{ expect_revert(error_message="Ownable: caller is not the owner") %}
    IPixelDrawer.setEveryoneCanLaunchRound(contract_address=drawer_contract_address, bool=FALSE)

    return ()
end

@view
func test_pixel_not_everyone_can_launch_new_round{
    syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*
}():
    tempvar drawer_contract_address
    %{ ids.drawer_contract_address = context.drawer_contract_address %}

    # At beginning, not everyone can launch new round!

    let (bool : felt) = IPixelDrawer.everyoneCanLaunchRound(
        contract_address=drawer_contract_address
    )
    assert FALSE = bool

    let (round) = IPixelDrawer.currentDrawingRound(contract_address=drawer_contract_address)
    assert 1 = round

    # Check that owner can launch new round
    %{ stop_prank_drawer = start_prank(context.account, target_contract_address=ids.drawer_contract_address) %}

    # 24+ hour is enough to launch new round
    let new_timestamp = 'start_timestamp' + (24 * 3600 + 136)
    %{ warp(ids.new_timestamp, context.drawer_contract_address) %}

    IPixelDrawer.launchNewRoundIfNecessary(contract_address=drawer_contract_address)

    let (round) = IPixelDrawer.currentDrawingRound(contract_address=drawer_contract_address)
    assert 2 = round

    # Check that non owner cannot launch new round

    %{ stop_prank_drawer() %}

    # Check that non owner cannot update flag
    %{ expect_revert(error_message="Ownable: caller is not the owner") %}
    IPixelDrawer.launchNewRoundIfNecessary(contract_address=drawer_contract_address)

    return ()
end

@view
func test_pixel_everyone_can_launch_new_round{
    syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*
}():
    tempvar drawer_contract_address
    %{ ids.drawer_contract_address = context.drawer_contract_address %}

    # Owner can update flag
    %{ stop_prank_drawer = start_prank(context.account, target_contract_address=ids.drawer_contract_address) %}
    IPixelDrawer.setEveryoneCanLaunchRound(contract_address=drawer_contract_address, bool=TRUE)

    let (bool : felt) = IPixelDrawer.everyoneCanLaunchRound(
        contract_address=drawer_contract_address
    )
    assert TRUE = bool

    %{ stop_prank_drawer() %}

    # 24+ hour is enough to launch new round
    let new_timestamp = 'start_timestamp' + (24 * 3600 + 136)
    %{ warp(ids.new_timestamp, context.drawer_contract_address) %}

    # We're not owner but we can now launch new round
    IPixelDrawer.launchNewRoundIfNecessary(contract_address=drawer_contract_address)

    let (round) = IPixelDrawer.currentDrawingRound(contract_address=drawer_contract_address)
    assert 2 = round

    return ()
end

@view
func test_pixel_drawer_number_colorizations{
    syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*
}():
    alloc_locals
    local pixel_contract_address
    %{ ids.pixel_contract_address = context.pixel_contract_address %}

    local drawer_contract_address
    %{ ids.drawer_contract_address = context.drawer_contract_address %}

    # Get current color
    let (pixel_color : PixelColor) = IPixelDrawer.currentDrawingPixelColor(
        drawer_contract_address, 12
    )
    assert pixel_color.set = 0  # Unset
    assert pixel_color.color = Color(0, 0, 0)

    %{ stop_prank_drawer = start_prank(context.account, target_contract_address=ids.drawer_contract_address) %}

    local account
    %{ ids.account = context.account %}

    IPixelDrawer.setMaxColorizationsPerToken(drawer_contract_address, 13)

    # Minting first pixel
    IPixelERC721.mint(contract_address=pixel_contract_address, to=account)

    # Getting current # of colorizations

    let (count) = IPixelDrawer.numberOfColorizations(drawer_contract_address, 1, Uint256(1, 0))
    assert 0 = count

    let (colorizations : Colorization*) = alloc()
    assert colorizations[0] = Colorization(pixel_index=12, color_index=92)
    assert colorizations[1] = Colorization(pixel_index=18, color_index=3)
    assert colorizations[2] = Colorization(pixel_index=1, color_index=12)

    IPixelDrawer.colorizePixels(drawer_contract_address, Uint256(1, 0), 3, colorizations)

    let (count) = IPixelDrawer.numberOfColorizations(drawer_contract_address, 1, Uint256(1, 0))
    assert 3 = count

    let (colorizations : Colorization*) = alloc()
    assert colorizations[0] = Colorization(pixel_index=399, color_index=94)
    assert colorizations[1] = Colorization(pixel_index=128, color_index=85)
    assert colorizations[2] = Colorization(pixel_index=36, color_index=2)
    assert colorizations[3] = Colorization(pixel_index=360, color_index=78)
    assert colorizations[4] = Colorization(pixel_index=220, color_index=57)
    assert colorizations[5] = Colorization(pixel_index=48, color_index=32)
    assert colorizations[6] = Colorization(pixel_index=178, color_index=90)
    assert colorizations[7] = Colorization(pixel_index=300, color_index=12)
    assert colorizations[8] = Colorization(pixel_index=27, color_index=18)
    assert colorizations[9] = Colorization(pixel_index=82, color_index=92)
    IPixelDrawer.colorizePixels(drawer_contract_address, Uint256(1, 0), 10, colorizations)

    # 10 colorizations that will be batched in 2 felts

    let (count) = IPixelDrawer.numberOfColorizations(drawer_contract_address, 1, Uint256(1, 0))
    assert 13 = count

    # We updated the contract with 13 as max colorizations / round so can't write anymore !

    let (colorizations : Colorization*) = alloc()
    assert colorizations[0] = Colorization(pixel_index=399, color_index=94)

    %{ expect_revert(error_message="You have reached the max number of allowed colorizations for this round") %}

    IPixelDrawer.colorizePixels(drawer_contract_address, Uint256(1, 0), 1, colorizations)

    %{ stop_prank_drawer() %}
    return ()
end
