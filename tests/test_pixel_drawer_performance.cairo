%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.alloc import alloc

from pxls.PixelDrawer.colorization import (
    Colorization,
    UserColorizations,
    save_drawing_user_colorizations,
)

from pxls.PixelDrawer.grid import get_grid
from pxls.PixelDrawer.token_uri import get_rtwrk_token_uri
from pxls.interfaces import IPixelERC721, IPixelDrawer

@view
func __setup__{syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*}():
    alloc_locals
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
    %{ context.drawer_contract_address = deploy_contract("contracts/pxls/PixelDrawer/PixelDrawer.cairo", [context.account, context.pixel_contract_address, 40]).contract_address %}

    %{ stop_prank_pixel = start_prank(context.account, target_contract_address=context.pixel_contract_address) %}
    %{ stop_prank_drawer = start_prank(context.account, target_contract_address=context.drawer_contract_address) %}

    local pixel_contract_address
    %{ ids.pixel_contract_address = context.pixel_contract_address %}

    local drawer_contract_address
    %{ ids.drawer_contract_address = context.drawer_contract_address %}

    IPixelERC721.mint(contract_address=pixel_contract_address, to=123456)
    IPixelERC721.mint(contract_address=pixel_contract_address, to=123457)

    # Warping time before launching the initial round
    let start_timestamp = 'start_timestamp'
    %{ warp(ids.start_timestamp, context.drawer_contract_address) %}

    let (theme : felt*) = alloc()
    assert theme[0] = 'Super theme'
    # Launching the initial round
    IPixelDrawer.launchNewRoundIfNecessary(
        contract_address=drawer_contract_address, theme_len=1, theme=theme
    )

    %{ stop_prank_pixel() %}

    # 99 persons colorize 20 pixels in 20 transactions of 1 colorization = 1980 colorizations < MAX

    %{
        import random
        colorization_index = 0
        for token_id in range(2, 101):
            for i in range(20):
                pixel_index = random.randrange(400)
                color_index = random.randrange(95)
                user_colorizations_packed = (pixel_index * 95 + color_index) * 400 + token_id
                store(context.drawer_contract_address, "drawing_user_colorizations", [user_colorizations_packed], key=[1,colorization_index])
                colorization_index += 1
            store(context.drawer_contract_address, "number_of_colorizations_per_token", [20], key=[1,token_id,0])
        store(context.drawer_contract_address, "drawing_user_colorizations_index", [colorization_index], key=[1])
        store(context.drawer_contract_address, "number_of_colorizations_total", [1980], key=[1])
    %}

    # 99 persons colorize 20 pixels in 1 transactions of 20 colorization = 1980 colorizations < MAX
    # Colorizations are stored 8 by 8 (8 fit in a single felt)

    %{
        import random
        colorization_index = 0
        for token_id in range(2, 101):
            colorizations_packed = 0
            for i in range(20):
                pixel_index = random.randrange(400)
                color_index = random.randrange(95)
                color_packed = pixel_index * 95 + color_index
                colorizations_packed = colorizations_packed * 38000 + color_packed
                if (i + 1) % 8 == 0:
                    user_colorizations_packed = colorizations_packed * 400 + token_id
                    store(context.drawer_contract_address, "drawing_user_colorizations", [user_colorizations_packed], key=[2,colorization_index])
                    colorization_index += 1
                    colorizations_packed = 0
            if colorizations_packed != 0:
                user_colorizations_packed = colorizations_packed * 400 + token_id
                store(context.drawer_contract_address, "drawing_user_colorizations", [user_colorizations_packed], key=[2,colorization_index])
            store(context.drawer_contract_address, "number_of_colorizations_per_token", [20], key=[2,token_id,0])
        store(context.drawer_contract_address, "drawing_user_colorizations_index", [colorization_index], key=[2])
        store(context.drawer_contract_address, "number_of_colorizations_total", [1980], key=[2])
    %}

    %{ stop_prank_drawer() %}

    return ()
end

@view
func test_get_grid_1_by_1{syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*}():
    alloc_locals

    local drawer_contract_address
    %{ ids.drawer_contract_address = context.drawer_contract_address %}
    let (grid_len : felt, grid : felt*) = IPixelDrawer.getGrid(
        contract_address=drawer_contract_address, round=1
    )
    return ()
end

@view
func test_get_grid_20_by_20{syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*}():
    alloc_locals

    # Warping time before launching the second round
    let new_timestamp = 'start_timestamp' + (26 * 3600 + 136)
    %{ warp(ids.new_timestamp, context.drawer_contract_address) %}

    # Fake round 2
    %{
        store(context.drawer_contract_address, "current_drawing_round", [2])
        store(context.drawer_contract_address, "drawing_timestamp", [ids.new_timestamp], key=[2])
    %}

    local drawer_contract_address
    %{ ids.drawer_contract_address = context.drawer_contract_address %}
    let (grid_len : felt, grid : felt*) = IPixelDrawer.getGrid(
        contract_address=drawer_contract_address, round=2
    )
    return ()
end

@view
func test_get_grid_and_generate_token_uri{
    syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*
}():
    alloc_locals

    local drawer_contract_address
    %{ ids.drawer_contract_address = context.drawer_contract_address %}
    let (grid_len : felt, grid : felt*) = IPixelDrawer.getGrid(
        contract_address=drawer_contract_address, round=1
    )

    let (token_uri_len : felt, token_uri : felt*) = get_rtwrk_token_uri(20, 1, grid_len, grid)

    return ()
end

@view
func test_colorize_1_by_1{syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*}():
    alloc_locals

    local drawer_contract_address
    %{ ids.drawer_contract_address = context.drawer_contract_address %}

    %{ stop_prank_drawer = start_prank(context.account, target_contract_address=context.drawer_contract_address) %}
    let (colorizations : Colorization*) = alloc()
    assert colorizations[0] = Colorization(pixel_index=12, color_index=92)
    assert colorizations[1] = Colorization(pixel_index=18, color_index=3)
    assert colorizations[2] = Colorization(pixel_index=1, color_index=12)

    IPixelDrawer.colorizePixels(drawer_contract_address, Uint256(1, 0), 3, colorizations)
    %{ stop_prank_drawer() %}
    return ()
end

@view
func test_colorize_20_by_20{syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*}():
    alloc_locals

    # Warping time before launching the second round
    let new_timestamp = 'start_timestamp' + (26 * 3600 + 136)
    %{ warp(ids.new_timestamp, context.drawer_contract_address) %}

    # Fake round 2
    %{
        store(context.drawer_contract_address, "current_drawing_round", [2])
        store(context.drawer_contract_address, "drawing_timestamp", [ids.new_timestamp], key=[2])
    %}

    local drawer_contract_address
    %{ ids.drawer_contract_address = context.drawer_contract_address %}

    %{ stop_prank_drawer = start_prank(context.account, target_contract_address=context.drawer_contract_address) %}
    let (colorizations : Colorization*) = alloc()
    assert colorizations[0] = Colorization(pixel_index=12, color_index=92)
    assert colorizations[1] = Colorization(pixel_index=18, color_index=3)
    assert colorizations[2] = Colorization(pixel_index=1, color_index=12)

    IPixelDrawer.colorizePixels(drawer_contract_address, Uint256(1, 0), 3, colorizations)
    %{ stop_prank_drawer() %}
    return ()
end

@view
func test_colorize_hit_limit_1_by_1{
    syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*
}():
    alloc_locals

    local drawer_contract_address
    %{ ids.drawer_contract_address = context.drawer_contract_address %}

    %{ stop_prank_drawer = start_prank(context.account, target_contract_address=context.drawer_contract_address) %}
    let (colorizations : Colorization*) = alloc()
    assert colorizations[0] = Colorization(pixel_index=12, color_index=92)
    assert colorizations[1] = Colorization(pixel_index=18, color_index=3)
    assert colorizations[2] = Colorization(pixel_index=1, color_index=12)
    assert colorizations[3] = Colorization(pixel_index=12, color_index=92)
    assert colorizations[4] = Colorization(pixel_index=18, color_index=3)
    assert colorizations[5] = Colorization(pixel_index=1, color_index=12)
    assert colorizations[6] = Colorization(pixel_index=12, color_index=92)
    assert colorizations[7] = Colorization(pixel_index=18, color_index=3)
    assert colorizations[8] = Colorization(pixel_index=1, color_index=12)
    assert colorizations[9] = Colorization(pixel_index=1, color_index=12)
    assert colorizations[10] = Colorization(pixel_index=12, color_index=92)
    assert colorizations[11] = Colorization(pixel_index=18, color_index=3)
    assert colorizations[12] = Colorization(pixel_index=1, color_index=12)
    assert colorizations[13] = Colorization(pixel_index=12, color_index=92)
    assert colorizations[14] = Colorization(pixel_index=18, color_index=3)
    assert colorizations[15] = Colorization(pixel_index=1, color_index=12)
    assert colorizations[16] = Colorization(pixel_index=12, color_index=92)
    assert colorizations[17] = Colorization(pixel_index=18, color_index=3)
    assert colorizations[18] = Colorization(pixel_index=1, color_index=12)
    assert colorizations[19] = Colorization(pixel_index=1, color_index=12)

    IPixelDrawer.colorizePixels(drawer_contract_address, Uint256(1, 0), 20, colorizations)
    %{ stop_prank_drawer() %}

    %{ stop_prank_drawer = start_prank(123457, target_contract_address=context.drawer_contract_address) %}

    %{ expect_revert(error_message="The max total number of allowed colorizations for this round has been reached") %}
    # Sending just one colorization should fail because we hit the 2000 hard limit
    IPixelDrawer.colorizePixels(drawer_contract_address, Uint256(2, 0), 1, colorizations)

    %{ stop_prank_drawer() %}
    return ()
end

@view
func test_colorize_hit_limit_20_by_20{
    syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*
}():
    alloc_locals

    local drawer_contract_address
    %{ ids.drawer_contract_address = context.drawer_contract_address %}

    # Warping time before launching the second round
    let new_timestamp = 'start_timestamp' + (26 * 3600 + 136)
    %{ warp(ids.new_timestamp, context.drawer_contract_address) %}

    # Fake round 2
    %{
        store(context.drawer_contract_address, "current_drawing_round", [2])
        store(context.drawer_contract_address, "drawing_timestamp", [ids.new_timestamp], key=[2])
    %}

    %{ stop_prank_drawer = start_prank(context.account, target_contract_address=context.drawer_contract_address) %}
    let (colorizations : Colorization*) = alloc()
    assert colorizations[0] = Colorization(pixel_index=12, color_index=92)
    assert colorizations[1] = Colorization(pixel_index=18, color_index=3)
    assert colorizations[2] = Colorization(pixel_index=1, color_index=12)
    assert colorizations[3] = Colorization(pixel_index=12, color_index=92)
    assert colorizations[4] = Colorization(pixel_index=18, color_index=3)
    assert colorizations[5] = Colorization(pixel_index=1, color_index=12)
    assert colorizations[6] = Colorization(pixel_index=12, color_index=92)
    assert colorizations[7] = Colorization(pixel_index=18, color_index=3)
    assert colorizations[8] = Colorization(pixel_index=1, color_index=12)
    assert colorizations[9] = Colorization(pixel_index=1, color_index=12)
    assert colorizations[10] = Colorization(pixel_index=12, color_index=92)
    assert colorizations[11] = Colorization(pixel_index=18, color_index=3)
    assert colorizations[12] = Colorization(pixel_index=1, color_index=12)
    assert colorizations[13] = Colorization(pixel_index=12, color_index=92)
    assert colorizations[14] = Colorization(pixel_index=18, color_index=3)
    assert colorizations[15] = Colorization(pixel_index=1, color_index=12)
    assert colorizations[16] = Colorization(pixel_index=12, color_index=92)
    assert colorizations[17] = Colorization(pixel_index=18, color_index=3)
    assert colorizations[18] = Colorization(pixel_index=1, color_index=12)
    assert colorizations[19] = Colorization(pixel_index=1, color_index=12)

    IPixelDrawer.colorizePixels(drawer_contract_address, Uint256(1, 0), 20, colorizations)
    %{ stop_prank_drawer() %}

    %{ stop_prank_drawer = start_prank(123457, target_contract_address=context.drawer_contract_address) %}

    %{ expect_revert(error_message="The max total number of allowed colorizations for this round has been reached") %}
    # Sending just one colorization should fail because we hit the 2000 hard limit
    IPixelDrawer.colorizePixels(drawer_contract_address, Uint256(2, 0), 1, colorizations)

    %{ stop_prank_drawer() %}
    return ()
end

@view
func test_get_colorizers_1_by_1{syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*}(
    ):
    alloc_locals

    local drawer_contract_address
    %{ ids.drawer_contract_address = context.drawer_contract_address %}
    let (count : felt) = IPixelDrawer.numberOfColorizers(
        contract_address=drawer_contract_address, round=1
    )
    assert 99 = count
    return ()
end

@view
func test_get_colorizers_20_by_20{
    syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*
}():
    alloc_locals

    # Warping time before launching the second round
    let new_timestamp = 'start_timestamp' + (26 * 3600 + 136)
    %{ warp(ids.new_timestamp, context.drawer_contract_address) %}

    # Fake round 2
    %{
        store(context.drawer_contract_address, "current_drawing_round", [2])
        store(context.drawer_contract_address, "drawing_timestamp", [ids.new_timestamp], key=[2])
    %}

    local drawer_contract_address
    %{ ids.drawer_contract_address = context.drawer_contract_address %}
    let (count : felt) = IPixelDrawer.numberOfColorizers(
        contract_address=drawer_contract_address, round=2
    )
    assert 99 = count
    return ()
end

@view
func test_number_colorizations_1_by_1{
    syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*
}():
    alloc_locals

    local drawer_contract_address
    %{ ids.drawer_contract_address = context.drawer_contract_address %}
    let (count : felt) = IPixelDrawer.numberOfColorizations(
        contract_address=drawer_contract_address, round=1, tokenId=Uint256(2, 0)
    )
    assert 20 = count
    return ()
end

@view
func test_number_colorizations_20_by_20{
    syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*
}():
    alloc_locals

    # Warping time before launching the second round
    let new_timestamp = 'start_timestamp' + (26 * 3600 + 136)
    %{ warp(ids.new_timestamp, context.drawer_contract_address) %}

    # Fake round 2
    %{
        store(context.drawer_contract_address, "current_drawing_round", [2])
        store(context.drawer_contract_address, "drawing_timestamp", [ids.new_timestamp], key=[2])
    %}

    local drawer_contract_address
    %{ ids.drawer_contract_address = context.drawer_contract_address %}
    let (count : felt) = IPixelDrawer.numberOfColorizations(
        contract_address=drawer_contract_address, round=2, tokenId=Uint256(2, 0)
    )
    assert 20 = count
    return ()
end
