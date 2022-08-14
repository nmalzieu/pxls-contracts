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
    %{ stop_prank_drawer() %}

    # each person colorizes 40 pixels in 40 transactions of 1 colorization

    %{
        import random
        colorization_index = 0
        for token_id in range(2, 66):
            for i in range(40):
                pixel_index = random.randrange(400)
                color_index = random.randrange(95)
                color_packed = (pixel_index * 95 + color_index) * 400 + token_id
                store(context.drawer_contract_address, "drawing_user_colorizations", [color_packed], key=[1,colorization_index])
                colorization_index += 1
            store(context.drawer_contract_address, "number_of_colorizations_per_token", [40], key=[1,token_id,0])
    %}

    return ()
end

@view
func test_get_grid{syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*}():
    alloc_locals

    local drawer_contract_address
    %{ ids.drawer_contract_address = context.drawer_contract_address %}
    let (grid_len : felt, grid : felt*) = IPixelDrawer.getGrid(
        contract_address=drawer_contract_address, round=1
    )
    return ()
end

@view
func test_colorize{syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*}():
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
func test_get_colorizers{syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*}():
    alloc_locals

    local drawer_contract_address
    %{ ids.drawer_contract_address = context.drawer_contract_address %}
    let (count : felt) = IPixelDrawer.numberOfColorizers(
        contract_address=drawer_contract_address, round=1
    )
    assert 64 = count
    return ()
end

@view
func test_number_colorizations{syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*}():
    alloc_locals

    local drawer_contract_address
    %{ ids.drawer_contract_address = context.drawer_contract_address %}
    let (count : felt) = IPixelDrawer.numberOfColorizations(
        contract_address=drawer_contract_address, round=1, tokenId=Uint256(2, 0)
    )
    assert 40 = count
    return ()
end
