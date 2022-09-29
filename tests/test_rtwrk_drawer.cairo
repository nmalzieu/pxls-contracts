%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.alloc import alloc

from pxls.utils.colors import Color, PixelColor
from pxls.RtwrkDrawer.colorization import PixelColorization
from pxls.RtwrkDrawer.original_rtwrks import ORIGINAL_RTWRKS_COUNT
from pxls.interfaces import IPxlERC721, IRtwrkDrawer

@view
func __setup__{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}() {
    let name = 'Pixel';
    let symbol = 'PXL';

    %{ context.account = 123456 %}

    // Data contracts are heavy, deploying just a sample
    %{ context.sample_pxl_metadata_address = deploy_contract("tests/sample_pxl_metadata_contract.cairo", []).contract_address %}

    %{
        context.pxl_erc721_contract_address = deploy_contract("contracts/pxls/PxlERC721/PxlERC721.cairo", [
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
    %{ context.rtwrk_drawer_contract_address = deploy_contract("contracts/pxls/RtwrkDrawer/RtwrkDrawer.cairo", [context.account, context.pxl_erc721_contract_address]).contract_address %}

    %{ stop_prank_pixel = start_prank(context.account, target_contract_address=context.pxl_erc721_contract_address) %}
    %{ stop_prank_drawer = start_prank(context.account, target_contract_address=context.rtwrk_drawer_contract_address) %}

    tempvar pxl_erc721_contract_address;
    %{ ids.pxl_erc721_contract_address = context.pxl_erc721_contract_address %}

    tempvar rtwrk_drawer_contract_address;
    %{ ids.rtwrk_drawer_contract_address = context.rtwrk_drawer_contract_address %}

    // Warping time before launching the initial rtwrk
    let start_timestamp = 'start_timestamp';
    %{ warp(ids.start_timestamp, context.rtwrk_drawer_contract_address) %}

    let (theme: felt*) = alloc();
    assert theme[0] = 'Super theme';

    // Only auction contract can launch an rtwrk, let's fake it
    %{ store(context.rtwrk_drawer_contract_address, "rtwrk_auction_address", [context.account]) %}

    // Launching the initial rtwrk
    IRtwrkDrawer.launchNewRtwrk(
        contract_address=rtwrk_drawer_contract_address, theme_len=1, theme=theme
    );

    %{ stop_prank_pixel() %}
    %{ stop_prank_drawer() %}
    return ();
}

@view
func test_rtwrk_drawer_getters{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}() {
    tempvar pxl_erc721_contract_address;
    %{ ids.pxl_erc721_contract_address = context.pxl_erc721_contract_address %}

    tempvar rtwrk_drawer_contract_address;
    %{ ids.rtwrk_drawer_contract_address = context.rtwrk_drawer_contract_address %}

    let (p_address) = IRtwrkDrawer.pxlERC721Address(contract_address=rtwrk_drawer_contract_address);
    assert p_address = pxl_erc721_contract_address;

    let (rtwrk_id) = IRtwrkDrawer.currentRtwrkId(contract_address=rtwrk_drawer_contract_address);
    assert ORIGINAL_RTWRKS_COUNT + 1 = rtwrk_id;

    let (owner: felt) = IRtwrkDrawer.owner(contract_address=rtwrk_drawer_contract_address);
    assert 123456 = owner;

    // Timestamp must have been set to the deployment timestamp

    let (returned_timestamp) = IRtwrkDrawer.currentRtwrkTimestamp(
        contract_address=rtwrk_drawer_contract_address
    );
    assert returned_timestamp = 'start_timestamp';

    let (max) = IRtwrkDrawer.maxPixelColorizationsPerColorizer(rtwrk_drawer_contract_address);
    assert 20 = max;

    // Getting theme
    let (theme_len: felt, theme: felt*) = IRtwrkDrawer.rtwrkTheme(
        rtwrk_drawer_contract_address, ORIGINAL_RTWRKS_COUNT + 1
    );
    assert 1 = theme_len;
    assert 'Super theme' = theme[0];

    // Get total number of colorizations
    let (total_colorizations) = IRtwrkDrawer.totalNumberOfPixelColorizations(
        rtwrk_drawer_contract_address, 1
    );
    assert 0 = total_colorizations;

    return ();
}

@view
func test_rtwrk_drawer_set_auction_address{
    syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}() {
    tempvar rtwrk_drawer_contract_address;
    %{ ids.rtwrk_drawer_contract_address = context.rtwrk_drawer_contract_address %}

    let (current_auction_address) = IRtwrkDrawer.rtwrkThemeAuctionContractAddress(
        rtwrk_drawer_contract_address
    );
    assert 123456 = current_auction_address;

    %{ stop_prank = start_prank(123456, target_contract_address=ids.rtwrk_drawer_contract_address) %}
    IRtwrkDrawer.setRtwrkThemeAuctionContractAddress(rtwrk_drawer_contract_address, 12);

    let (new_auction_address) = IRtwrkDrawer.rtwrkThemeAuctionContractAddress(
        rtwrk_drawer_contract_address
    );
    assert 12 = new_auction_address;

    %{ stop_prank() %}

    %{ expect_revert(error_message="Ownable: caller is not the owner") %}
    IRtwrkDrawer.setRtwrkThemeAuctionContractAddress(rtwrk_drawer_contract_address, 12);
    return ();
}

@view
func test_rtwrk_drawer_transfer_ownership{
    syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}() {
    tempvar rtwrk_drawer_contract_address;
    %{ ids.rtwrk_drawer_contract_address = context.rtwrk_drawer_contract_address %}
    let (owner: felt) = IRtwrkDrawer.owner(contract_address=rtwrk_drawer_contract_address);
    assert 123456 = owner;

    %{ stop_prank = start_prank(123456, target_contract_address=ids.rtwrk_drawer_contract_address) %}
    IRtwrkDrawer.transferOwnership(rtwrk_drawer_contract_address, 123457);
    %{ stop_prank() %}

    let (owner: felt) = IRtwrkDrawer.owner(contract_address=rtwrk_drawer_contract_address);
    assert 123457 = owner;

    %{ expect_revert(error_message="Ownable: caller is not the owner") %}
    IRtwrkDrawer.transferOwnership(rtwrk_drawer_contract_address, 123457);

    return ();
}

@view
func test_rtwrk_drawer_pixel_owner_nonexistent_token{
    syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}() {
    tempvar rtwrk_drawer_contract_address;
    %{ ids.rtwrk_drawer_contract_address = context.rtwrk_drawer_contract_address %}

    %{ expect_revert(error_message="ERC721: owner query for nonexistent token") %}

    // Nobody owns pxl 1 so it should fail

    let (pixel_colorizations: PixelColorization*) = alloc();
    assert pixel_colorizations[0] = PixelColorization(pixel_index=12, color_index=3);

    IRtwrkDrawer.colorizePixels(
        rtwrk_drawer_contract_address, Uint256(1, 0), 1, pixel_colorizations
    );

    return ();
}

@view
func test_rtwrk_drawer_pixel_non_token_owner{
    syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}() {
    tempvar pxl_erc721_contract_address;
    %{ ids.pxl_erc721_contract_address = context.pxl_erc721_contract_address %}

    tempvar rtwrk_drawer_contract_address;
    %{ ids.rtwrk_drawer_contract_address = context.rtwrk_drawer_contract_address %}

    %{ stop_prank = start_prank(context.account, target_contract_address=ids.pxl_erc721_contract_address) %}

    // Minting first pixel
    IPxlERC721.mint(contract_address=pxl_erc721_contract_address, to=123458);

    // Non owner can't draw pixel
    %{ expect_revert(error_message="Address does not own pxl") %}

    let (pixel_colorizations: PixelColorization*) = alloc();
    assert pixel_colorizations[0] = PixelColorization(pixel_index=12, color_index=3);

    IRtwrkDrawer.colorizePixels(
        rtwrk_drawer_contract_address, Uint256(1, 0), 1, pixel_colorizations
    );

    %{ stop_prank() %}
    return ();
}

@view
func test_rtwrk_drawer_pixel_wrong_color{
    syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}() {
    tempvar pxl_erc721_contract_address;
    %{ ids.pxl_erc721_contract_address = context.pxl_erc721_contract_address %}

    tempvar rtwrk_drawer_contract_address;
    %{ ids.rtwrk_drawer_contract_address = context.rtwrk_drawer_contract_address %}

    // Get current color
    let (grid_len, grid: PixelColor*) = IRtwrkDrawer.rtwrkGrid(
        rtwrk_drawer_contract_address, ORIGINAL_RTWRKS_COUNT + 1, 0
    );
    let pixel_color = grid[12];
    assert pixel_color.set = 0;  // Unset
    assert pixel_color.color = Color(0, 0, 0);

    %{ stop_prank_drawer = start_prank(context.account, target_contract_address=ids.rtwrk_drawer_contract_address) %}

    tempvar account;
    %{ ids.account = context.account %}

    // Minting first pixel
    IPxlERC721.mint(contract_address=pxl_erc721_contract_address, to=account);

    // Pixel owner cannot draw pixel with wrong color
    %{ expect_revert(error_message="Color index is out of bounds") %}
    let (pixel_colorizations: PixelColorization*) = alloc();
    assert pixel_colorizations[0] = PixelColorization(pixel_index=12, color_index=95);

    IRtwrkDrawer.colorizePixels(
        rtwrk_drawer_contract_address, Uint256(1, 0), 1, pixel_colorizations
    );

    %{ stop_prank_drawer() %}
    return ();
}

@view
func test_rtwrk_drawer_colorize_pixels{
    syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}() {
    alloc_locals;
    local pxl_erc721_contract_address;
    %{ ids.pxl_erc721_contract_address = context.pxl_erc721_contract_address %}

    local rtwrk_drawer_contract_address;
    %{ ids.rtwrk_drawer_contract_address = context.rtwrk_drawer_contract_address %}

    // Get current colors
    let (grid_len, grid: PixelColor*) = IRtwrkDrawer.rtwrkGrid(
        rtwrk_drawer_contract_address, ORIGINAL_RTWRKS_COUNT + 1, 0
    );
    let pixel_1_color = grid[12];
    assert 0 = pixel_1_color.set;  // Unset
    assert Color(0, 0, 0) = pixel_1_color.color;

    let (grid_len, grid: PixelColor*) = IRtwrkDrawer.rtwrkGrid(
        rtwrk_drawer_contract_address, ORIGINAL_RTWRKS_COUNT + 1, 0
    );
    let pixel_2_color = grid[300];
    assert 0 = pixel_2_color.set;  // Unset
    assert Color(0, 0, 0) = pixel_2_color.color;

    %{ stop_prank_drawer = start_prank(context.account, target_contract_address=ids.rtwrk_drawer_contract_address) %}

    local account;
    %{ ids.account = context.account %}

    // Minting first pixel
    IPxlERC721.mint(contract_address=pxl_erc721_contract_address, to=account);

    // Pixel owner can draw multiple pixels with right colors

    let (pixel_colorizations: PixelColorization*) = alloc();
    assert pixel_colorizations[0] = PixelColorization(pixel_index=12, color_index=93);
    assert pixel_colorizations[1] = PixelColorization(pixel_index=300, color_index=2);

    %{
        expect_events({
               "name": "pixels_colorized",
               "data": {
                   "pxl_id": 1,
                   "account_address": context.account,
                   "pixel_colorizations": [
                       {"pixel_index": 12, "color_index": 93},
                       {"pixel_index": 300, "color_index": 2}
                   ]
               }
           })
    %}

    IRtwrkDrawer.colorizePixels(
        rtwrk_drawer_contract_address, Uint256(1, 0), 2, pixel_colorizations
    );

    // Check pixel colors have been set
    let (grid_len, grid: PixelColor*) = IRtwrkDrawer.rtwrkGrid(
        rtwrk_drawer_contract_address, ORIGINAL_RTWRKS_COUNT + 1, 0
    );
    let pixel_1_color = grid[12];
    assert TRUE = pixel_1_color.set;  // Set
    assert Color(242, 242, 242) = pixel_1_color.color;
    let (grid_len, grid: PixelColor*) = IRtwrkDrawer.rtwrkGrid(
        rtwrk_drawer_contract_address, ORIGINAL_RTWRKS_COUNT + 1, 0
    );
    let pixel_2_color = grid[300];
    assert TRUE = pixel_2_color.set;  // Set
    assert Color(244, 67, 54) = pixel_2_color.color;

    %{ stop_prank_drawer() %}
    return ();
}

@view
func test_rtwrk_drawer_launch_too_early{
    syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}() {
    alloc_locals;
    local rtwrk_drawer_contract_address;
    %{ ids.rtwrk_drawer_contract_address = context.rtwrk_drawer_contract_address %}

    %{ stop_prank_drawer = start_prank(context.account, target_contract_address=ids.rtwrk_drawer_contract_address) %}

    // after calling start() in setup, we're at rtwrk 1

    let (rtwrk_id) = IRtwrkDrawer.currentRtwrkId(contract_address=rtwrk_drawer_contract_address);
    assert ORIGINAL_RTWRKS_COUNT + 1 = rtwrk_id;

    // 25 hour is not enough to launch new rtwrk

    let new_timestamp = 'start_timestamp' + (25 * 3600);
    %{ warp(ids.new_timestamp, context.rtwrk_drawer_contract_address) %}

    let (theme: felt*) = alloc();
    assert theme[0] = 'Ceci est un theme qui fait plus';
    assert theme[1] = 'que 31 characteres';

    %{ expect_revert(error_message="Trying to launch a new rtwrk but there is already one running") %}

    IRtwrkDrawer.launchNewRtwrk(
        contract_address=rtwrk_drawer_contract_address, theme_len=2, theme=theme
    );

    %{ stop_prank_drawer() %}

    return ();
}

@view
func test_rtwrk_drawer_launch_new_rtwrk{
    syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}() {
    alloc_locals;
    local rtwrk_drawer_contract_address;
    %{ ids.rtwrk_drawer_contract_address = context.rtwrk_drawer_contract_address %}

    %{ stop_prank_drawer = start_prank(context.account, target_contract_address=ids.rtwrk_drawer_contract_address) %}

    // after calling start() in setup, we're at rtwrk 1

    let (rtwrk_id) = IRtwrkDrawer.currentRtwrkId(contract_address=rtwrk_drawer_contract_address);
    assert ORIGINAL_RTWRKS_COUNT + 1 = rtwrk_id;

    // 26+ hour is enough to launch new rtwrk

    let new_timestamp = 'start_timestamp' + (26 * 3600 + 136);
    %{ warp(ids.new_timestamp, context.rtwrk_drawer_contract_address) %}

    let (theme: felt*) = alloc();
    assert theme[0] = 'Ceci est un theme qui fait plus';
    assert theme[1] = 'que 31 characteres';

    IRtwrkDrawer.launchNewRtwrk(
        contract_address=rtwrk_drawer_contract_address, theme_len=2, theme=theme
    );

    let (rtwrk_id) = IRtwrkDrawer.currentRtwrkId(contract_address=rtwrk_drawer_contract_address);
    assert ORIGINAL_RTWRKS_COUNT + 2 = rtwrk_id;

    let (current_timestamp) = IRtwrkDrawer.currentRtwrkTimestamp(
        contract_address=rtwrk_drawer_contract_address
    );
    assert new_timestamp = current_timestamp;

    let (previous_timestamp) = IRtwrkDrawer.rtwrkTimestamp(
        contract_address=rtwrk_drawer_contract_address, rtwrkId=ORIGINAL_RTWRKS_COUNT + 1
    );
    assert 'start_timestamp' = previous_timestamp;

    // Let's verify we can get back the 2 felt theme

    // Getting theme
    let (theme_len: felt, theme: felt*) = IRtwrkDrawer.rtwrkTheme(
        rtwrk_drawer_contract_address, ORIGINAL_RTWRKS_COUNT + 2
    );
    assert 2 = theme_len;
    assert 'Ceci est un theme qui fait plus' = theme[0];
    assert 'que 31 characteres' = theme[1];

    %{ stop_prank_drawer() %}

    return ();
}

@view
func test_rtwrk_drawer_drawing_fails_if_old_rtwrk{
    syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}() {
    alloc_locals;
    local pxl_erc721_contract_address;
    %{ ids.pxl_erc721_contract_address = context.pxl_erc721_contract_address %}

    local rtwrk_drawer_contract_address;
    %{ ids.rtwrk_drawer_contract_address = context.rtwrk_drawer_contract_address %}

    // after calling start() in setup, we're at rtwrk 1

    let (rtwrk_id) = IRtwrkDrawer.currentRtwrkId(contract_address=rtwrk_drawer_contract_address);
    assert ORIGINAL_RTWRKS_COUNT + 1 = rtwrk_id;

    local account;
    %{ ids.account = context.account %}

    %{ stop_prank_drawer = start_prank(context.account, target_contract_address=ids.rtwrk_drawer_contract_address) %}

    // Minting first pixel
    IPxlERC721.mint(contract_address=pxl_erc721_contract_address, to=account);

    // Pixel owner can draw pixel
    let (pixel_colorizations: PixelColorization*) = alloc();
    assert pixel_colorizations[0] = PixelColorization(pixel_index=12, color_index=3);

    IRtwrkDrawer.colorizePixels(
        rtwrk_drawer_contract_address, Uint256(1, 0), 1, pixel_colorizations
    );

    // 25 hour is not enough to launch new rtwrk

    let new_timestamp = 'start_timestamp' + (25 * 3600);
    %{ warp(ids.new_timestamp, context.rtwrk_drawer_contract_address) %}

    // Drawing pixel after < 1 day does not launch new rtwrk
    IRtwrkDrawer.colorizePixels(
        rtwrk_drawer_contract_address, Uint256(1, 0), 1, pixel_colorizations
    );

    let (rtwrk_id) = IRtwrkDrawer.currentRtwrkId(contract_address=rtwrk_drawer_contract_address);
    assert ORIGINAL_RTWRKS_COUNT + 1 = rtwrk_id;

    // 26+ hour is enough to launch new rtwrk

    let new_timestamp = 'start_timestamp' + (26 * 3600 + 136);
    %{ warp(ids.new_timestamp, context.rtwrk_drawer_contract_address) %}

    // Drawing pixel after 1 day fails if no new rtwrk has been launched
    %{ expect_revert(error_message="This rtwrk is finished, please launch a new one") %}
    IRtwrkDrawer.colorizePixels(
        rtwrk_drawer_contract_address, Uint256(1, 0), 1, pixel_colorizations
    );

    %{ stop_prank_drawer() %}

    return ();
}


@view
func test_original_rtwrks{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}() {
    tempvar rtwrk_drawer_contract_address;
    %{ ids.rtwrk_drawer_contract_address = context.rtwrk_drawer_contract_address %}

    // Let's verify we have the original rtwrks set
    let (current_rtwrk_id) = IRtwrkDrawer.currentRtwrkId(rtwrk_drawer_contract_address);
    assert ORIGINAL_RTWRKS_COUNT + 1 = current_rtwrk_id;

    let (theme_len, theme: felt*) = IRtwrkDrawer.rtwrkTheme(rtwrk_drawer_contract_address, 6);
    assert 2 = theme_len;
    assert 'The coolest hat of the third in' = theme[0];
    assert 'ternet' = theme[1];

    let (timestamp) = IRtwrkDrawer.rtwrkTimestamp(rtwrk_drawer_contract_address, 6);
    assert 1663344754 = timestamp;

    return ();
}


@view
func test_rtwrk_drawer_get_grid{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}() {
    alloc_locals;
    local pxl_erc721_contract_address;
    %{ ids.pxl_erc721_contract_address = context.pxl_erc721_contract_address %}

    local rtwrk_drawer_contract_address;
    %{ ids.rtwrk_drawer_contract_address = context.rtwrk_drawer_contract_address %}

    // after calling start() in setup, we're at rtwrk 1

    let (rtwrk_id) = IRtwrkDrawer.currentRtwrkId(contract_address=rtwrk_drawer_contract_address);
    assert ORIGINAL_RTWRKS_COUNT + 1 = rtwrk_id;

    local account;
    %{ ids.account = context.account %}

    %{ stop_prank_drawer = start_prank(context.account, target_contract_address=ids.rtwrk_drawer_contract_address) %}

    // Minting first pixel
    IPxlERC721.mint(contract_address=pxl_erc721_contract_address, to=account);

    // Pixel owner can draw pixel
    let (pixel_colorizations: PixelColorization*) = alloc();
    assert pixel_colorizations[0] = PixelColorization(pixel_index=12, color_index=3);

    IRtwrkDrawer.colorizePixels(
        rtwrk_drawer_contract_address, Uint256(1, 0), 1, pixel_colorizations
    );

    // 26+ hour is enough to launch new rtwrk

    let new_timestamp = 'start_timestamp' + (26 * 3600 + 136);
    %{ warp(ids.new_timestamp, context.rtwrk_drawer_contract_address) %}

    // Launch new rtwrk

    let (theme: felt*) = alloc();
    assert theme[0] = 'Super theme';

    IRtwrkDrawer.launchNewRtwrk(
        contract_address=rtwrk_drawer_contract_address, theme_len=1, theme=theme
    );

    let (rtwrk_id) = IRtwrkDrawer.currentRtwrkId(contract_address=rtwrk_drawer_contract_address);
    assert ORIGINAL_RTWRKS_COUNT + 2 = rtwrk_id;

    // Drawing pixel after launching new rtwrk
    let (pixel_colorizations: PixelColorization*) = alloc();
    assert pixel_colorizations[0] = PixelColorization(pixel_index=18, color_index=63);

    IRtwrkDrawer.colorizePixels(
        rtwrk_drawer_contract_address, Uint256(1, 0), 1, pixel_colorizations
    );

    let (grid_1_len: felt, grid_1: felt*) = IRtwrkDrawer.rtwrkGrid(
        contract_address=rtwrk_drawer_contract_address,
        rtwrkId=ORIGINAL_RTWRKS_COUNT + 1,
        rtwrkStep=0,
    );
    let (grid_2_len: felt, grid_2: felt*) = IRtwrkDrawer.rtwrkGrid(
        contract_address=rtwrk_drawer_contract_address,
        rtwrkId=ORIGINAL_RTWRKS_COUNT + 2,
        rtwrkStep=0,
    );

    // Length is # of pixel * 4 (see PixelColor struct)
    assert 20 * 20 * 4 = grid_1_len;
    assert 20 * 20 * 4 = grid_2_len;

    // Pixel 12 of rtwrk 1 set to color 3 = 229	115	115

    assert TRUE = grid_1[12 * 4];
    assert 229 = grid_1[12 * 4 + 1];
    assert 115 = grid_1[12 * 4 + 2];
    assert 115 = grid_1[12 * 4 + 3];

    // Pixel 18 of rtwrk 2 set to color 63 = 255,241,118

    assert TRUE = grid_2[18 * 4];
    assert 255 = grid_2[18 * 4 + 1];
    assert 241 = grid_2[18 * 4 + 2];
    assert 118 = grid_2[18 * 4 + 3];

    // If we send anothre colorization, we can get grid at different steps
    let (pixel_colorizations: PixelColorization*) = alloc();
    assert pixel_colorizations[0] = PixelColorization(pixel_index=18, color_index=12);

    IRtwrkDrawer.colorizePixels(
        rtwrk_drawer_contract_address, Uint256(1, 0), 1, pixel_colorizations
    );

    %{ stop_prank_drawer() %}

    // Get final grid (step=0)

    let (grid_2_len: felt, grid_2: felt*) = IRtwrkDrawer.rtwrkGrid(
        contract_address=rtwrk_drawer_contract_address,
        rtwrkId=ORIGINAL_RTWRKS_COUNT + 2,
        rtwrkStep=0,
    );

    // Pixel 18 of rtwrk 2 set to color 13 = 156,39,176

    assert TRUE = grid_2[18 * 4];
    assert 156 = grid_2[18 * 4 + 1];
    assert 39 = grid_2[18 * 4 + 2];
    assert 176 = grid_2[18 * 4 + 3];

    // Get intermediary grid (step=1)

    let (grid_2_len: felt, grid_2: felt*) = IRtwrkDrawer.rtwrkGrid(
        contract_address=rtwrk_drawer_contract_address,
        rtwrkId=ORIGINAL_RTWRKS_COUNT + 2,
        rtwrkStep=1,
    );

    // Pixel 18 of rtwrk 2 at step 1 is set to color 63 = 255,241,118

    assert TRUE = grid_2[18 * 4];
    assert 255 = grid_2[18 * 4 + 1];
    assert 241 = grid_2[18 * 4 + 2];
    assert 118 = grid_2[18 * 4 + 3];

    // Get final grid (step=2)

    let (grid_2_len: felt, grid_2: felt*) = IRtwrkDrawer.rtwrkGrid(
        contract_address=rtwrk_drawer_contract_address,
        rtwrkId=ORIGINAL_RTWRKS_COUNT + 2,
        rtwrkStep=2,
    );

    // Final pixel 18 of rtwrk 2 set to color 13 = 156,39,176

    assert TRUE = grid_2[18 * 4];
    assert 156 = grid_2[18 * 4 + 1];
    assert 39 = grid_2[18 * 4 + 2];
    assert 176 = grid_2[18 * 4 + 3];

    // Get final grid (step=10, we can query over last step)

    let (grid_2_len: felt, grid_2: felt*) = IRtwrkDrawer.rtwrkGrid(
        contract_address=rtwrk_drawer_contract_address,
        rtwrkId=ORIGINAL_RTWRKS_COUNT + 2,
        rtwrkStep=10,
    );

    // Final pixel 18 of rtwrk 2 set to color 13 = 156,39,176

    assert TRUE = grid_2[18 * 4];
    assert 156 = grid_2[18 * 4 + 1];
    assert 39 = grid_2[18 * 4 + 2];
    assert 176 = grid_2[18 * 4 + 3];

    // Verify we can get back steps from getter
    let (steps_count) = IRtwrkDrawer.rtwrkStepsCount(
        contract_address=rtwrk_drawer_contract_address, rtwrkId=ORIGINAL_RTWRKS_COUNT + 2
    );
    assert 2 = steps_count;

    return ();
}

@view
func test_rtwrk_drawer_not_everyone_can_launch_new_rtwrk{
    syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}() {
    alloc_locals;
    local rtwrk_drawer_contract_address;
    %{ ids.rtwrk_drawer_contract_address = context.rtwrk_drawer_contract_address %}

    let (rtwrk_id) = IRtwrkDrawer.currentRtwrkId(contract_address=rtwrk_drawer_contract_address);
    assert ORIGINAL_RTWRKS_COUNT + 1 = rtwrk_id;

    // Check that owner can launch new rtwrk
    %{ stop_prank_drawer = start_prank(context.account, target_contract_address=ids.rtwrk_drawer_contract_address) %}

    // 26+ hour is enough to launch new rtwrk
    let new_timestamp = 'start_timestamp' + (26 * 3600 + 136);
    %{ warp(ids.new_timestamp, context.rtwrk_drawer_contract_address) %}

    let (theme: felt*) = alloc();
    assert theme[0] = 'Super theme';

    IRtwrkDrawer.launchNewRtwrk(
        contract_address=rtwrk_drawer_contract_address, theme_len=1, theme=theme
    );

    let (rtwrk_id) = IRtwrkDrawer.currentRtwrkId(contract_address=rtwrk_drawer_contract_address);
    assert ORIGINAL_RTWRKS_COUNT + 2 = rtwrk_id;

    // Check that non owner cannot launch new rtwrk

    %{ stop_prank_drawer() %}

    // Check that non owner cannot update flag
    %{ expect_revert(error_message="Only the auction contract can launch a new rtwrk") %}
    IRtwrkDrawer.launchNewRtwrk(
        contract_address=rtwrk_drawer_contract_address, theme_len=1, theme=theme
    );

    return ();
}

@view
func test_rtwrk_drawer_number_colorizations{
    syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}() {
    alloc_locals;
    local pxl_erc721_contract_address;
    %{ ids.pxl_erc721_contract_address = context.pxl_erc721_contract_address %}

    local rtwrk_drawer_contract_address;
    %{ ids.rtwrk_drawer_contract_address = context.rtwrk_drawer_contract_address %}

    // Get current color
    let (grid_len, grid: PixelColor*) = IRtwrkDrawer.rtwrkGrid(
        rtwrk_drawer_contract_address, ORIGINAL_RTWRKS_COUNT + 1, 0
    );
    let pixel_color = grid[12];
    assert pixel_color.set = 0;  // Unset
    assert pixel_color.color = Color(0, 0, 0);

    %{ stop_prank_drawer = start_prank(context.account, target_contract_address=ids.rtwrk_drawer_contract_address) %}

    local account;
    %{ ids.account = context.account %}

    // Minting first pixel
    IPxlERC721.mint(contract_address=pxl_erc721_contract_address, to=account);

    // Getting current # of colorizations

    let (count) = IRtwrkDrawer.numberOfPixelColorizations(
        rtwrk_drawer_contract_address, ORIGINAL_RTWRKS_COUNT + 1, Uint256(1, 0)
    );
    assert 0 = count;

    let (pixel_colorizations: PixelColorization*) = alloc();
    assert pixel_colorizations[0] = PixelColorization(pixel_index=12, color_index=92);
    assert pixel_colorizations[1] = PixelColorization(pixel_index=18, color_index=3);
    assert pixel_colorizations[2] = PixelColorization(pixel_index=1, color_index=12);

    IRtwrkDrawer.colorizePixels(
        rtwrk_drawer_contract_address, Uint256(1, 0), 3, pixel_colorizations
    );

    let (count) = IRtwrkDrawer.numberOfPixelColorizations(
        rtwrk_drawer_contract_address, ORIGINAL_RTWRKS_COUNT + 1, Uint256(1, 0)
    );
    assert 3 = count;

    let (pixel_colorizations: PixelColorization*) = alloc();
    assert pixel_colorizations[0] = PixelColorization(pixel_index=399, color_index=94);
    assert pixel_colorizations[1] = PixelColorization(pixel_index=128, color_index=85);
    assert pixel_colorizations[2] = PixelColorization(pixel_index=36, color_index=2);
    assert pixel_colorizations[3] = PixelColorization(pixel_index=360, color_index=78);
    assert pixel_colorizations[4] = PixelColorization(pixel_index=220, color_index=57);
    assert pixel_colorizations[5] = PixelColorization(pixel_index=48, color_index=32);
    assert pixel_colorizations[6] = PixelColorization(pixel_index=178, color_index=90);
    assert pixel_colorizations[7] = PixelColorization(pixel_index=300, color_index=12);
    assert pixel_colorizations[8] = PixelColorization(pixel_index=27, color_index=18);
    assert pixel_colorizations[9] = PixelColorization(pixel_index=82, color_index=92);
    assert pixel_colorizations[10] = PixelColorization(pixel_index=360, color_index=78);
    assert pixel_colorizations[11] = PixelColorization(pixel_index=220, color_index=57);
    assert pixel_colorizations[12] = PixelColorization(pixel_index=48, color_index=32);
    assert pixel_colorizations[13] = PixelColorization(pixel_index=178, color_index=90);
    assert pixel_colorizations[14] = PixelColorization(pixel_index=300, color_index=12);
    assert pixel_colorizations[15] = PixelColorization(pixel_index=27, color_index=18);
    assert pixel_colorizations[16] = PixelColorization(pixel_index=82, color_index=92);
    IRtwrkDrawer.colorizePixels(
        rtwrk_drawer_contract_address, Uint256(1, 0), 17, pixel_colorizations
    );

    // 10 colorizations that will be batched in 2 felts

    let (count) = IRtwrkDrawer.numberOfPixelColorizations(
        rtwrk_drawer_contract_address, ORIGINAL_RTWRKS_COUNT + 1, Uint256(1, 0)
    );
    assert 20 = count;

    // We updated the contract with 13 as max colorizations / rtwrk so can't write anymore !

    let (pixel_colorizations: PixelColorization*) = alloc();
    assert pixel_colorizations[0] = PixelColorization(pixel_index=399, color_index=94);

    %{ expect_revert(error_message="You have reached the max number of allowed colorizations for this rtwrk") %}

    IRtwrkDrawer.colorizePixels(
        rtwrk_drawer_contract_address, Uint256(1, 0), 1, pixel_colorizations
    );

    %{ stop_prank_drawer() %}
    return ();
}

func mint_two_pixels{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}() {
    alloc_locals;
    local pxl_erc721_contract_address;
    %{ ids.pxl_erc721_contract_address = context.pxl_erc721_contract_address %}
    local account;
    %{ ids.account = context.account %}

    %{ stop_prank_pixel = start_prank(context.account, target_contract_address=ids.pxl_erc721_contract_address) %}
    // Mint the first directly from account
    IPxlERC721.mint(contract_address=pxl_erc721_contract_address, to=account);

    %{ stop_prank_pixel() %}

    %{ stop_prank_pixel = start_prank(4321, target_contract_address=ids.pxl_erc721_contract_address) %}
    // Mint the second from other account and transfer
    IPxlERC721.mint(contract_address=pxl_erc721_contract_address, to=4321);
    IPxlERC721.transferFrom(pxl_erc721_contract_address, 4321, account, Uint256(2, 0));

    %{ stop_prank_pixel() %}
    return ();
}

@view
func test_rtwrk_drawer_colorizers{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}(
    ) {
    alloc_locals;

    local rtwrk_drawer_contract_address;
    %{ ids.rtwrk_drawer_contract_address = context.rtwrk_drawer_contract_address %}

    mint_two_pixels();

    %{ stop_prank_drawer = start_prank(context.account, target_contract_address=ids.rtwrk_drawer_contract_address) %}

    // Colorize from token 1 and count colorizers (=1)

    let (pixel_colorizations: PixelColorization*) = alloc();
    assert pixel_colorizations[0] = PixelColorization(pixel_index=12, color_index=92);
    assert pixel_colorizations[1] = PixelColorization(pixel_index=18, color_index=3);
    assert pixel_colorizations[2] = PixelColorization(pixel_index=1, color_index=12);

    IRtwrkDrawer.colorizePixels(
        rtwrk_drawer_contract_address, Uint256(1, 0), 3, pixel_colorizations
    );

    let (colorizers_count) = IRtwrkDrawer.numberOfColorizers(
        rtwrk_drawer_contract_address, ORIGINAL_RTWRKS_COUNT + 1, 0
    );
    assert 1 = colorizers_count;

    // Recolorize from same token and count colorizers (=1)

    let (pixel_colorizations: PixelColorization*) = alloc();
    assert pixel_colorizations[0] = PixelColorization(pixel_index=12, color_index=92);
    assert pixel_colorizations[1] = PixelColorization(pixel_index=18, color_index=3);

    IRtwrkDrawer.colorizePixels(
        rtwrk_drawer_contract_address, Uint256(1, 0), 2, pixel_colorizations
    );

    let (colorizers_count) = IRtwrkDrawer.numberOfColorizers(
        rtwrk_drawer_contract_address, ORIGINAL_RTWRKS_COUNT + 1, 0
    );
    assert 1 = colorizers_count;

    let (colorizers_len, colorizers: felt*) = IRtwrkDrawer.colorizers(
        rtwrk_drawer_contract_address, ORIGINAL_RTWRKS_COUNT + 1, 0
    );
    assert 1 = colorizers_len;
    assert 1 = colorizers[0];

    // Colorize from second token and count colorizers (=2)

    let (pixel_colorizations: PixelColorization*) = alloc();
    assert pixel_colorizations[0] = PixelColorization(pixel_index=12, color_index=92);
    assert pixel_colorizations[1] = PixelColorization(pixel_index=18, color_index=3);
    assert pixel_colorizations[2] = PixelColorization(pixel_index=1, color_index=12);

    IRtwrkDrawer.colorizePixels(
        rtwrk_drawer_contract_address, Uint256(2, 0), 3, pixel_colorizations
    );

    let (colorizers_count) = IRtwrkDrawer.numberOfColorizers(
        rtwrk_drawer_contract_address, ORIGINAL_RTWRKS_COUNT + 1, 0
    );
    assert 2 = colorizers_count;

    let (colorizers_len, colorizers: felt*) = IRtwrkDrawer.colorizers(
        rtwrk_drawer_contract_address, ORIGINAL_RTWRKS_COUNT + 1, 0
    );
    assert 2 = colorizers_len;
    assert 1 = colorizers[0];
    assert 2 = colorizers[1];

    %{ stop_prank_drawer() %}
    return ();
}

@view
func test_rtwrk_drawer_total_number_colorizations{
    syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}() {
    alloc_locals;
    local pxl_erc721_contract_address;
    %{ ids.pxl_erc721_contract_address = context.pxl_erc721_contract_address %}

    local rtwrk_drawer_contract_address;
    %{ ids.rtwrk_drawer_contract_address = context.rtwrk_drawer_contract_address %}

    mint_two_pixels();

    %{ stop_prank_drawer = start_prank(context.account, target_contract_address=ids.rtwrk_drawer_contract_address) %}

    local account;
    %{ ids.account = context.account %}

    // Getting current # of colorizations

    let (count) = IRtwrkDrawer.numberOfPixelColorizations(
        rtwrk_drawer_contract_address, ORIGINAL_RTWRKS_COUNT + 1, Uint256(1, 0)
    );
    let (count_total) = IRtwrkDrawer.totalNumberOfPixelColorizations(
        rtwrk_drawer_contract_address, ORIGINAL_RTWRKS_COUNT + 1
    );
    assert 0 = count;
    assert 0 = count_total;

    let (pixel_colorizations: PixelColorization*) = alloc();
    assert pixel_colorizations[0] = PixelColorization(pixel_index=12, color_index=92);
    assert pixel_colorizations[1] = PixelColorization(pixel_index=18, color_index=3);
    assert pixel_colorizations[2] = PixelColorization(pixel_index=1, color_index=12);

    IRtwrkDrawer.colorizePixels(
        rtwrk_drawer_contract_address, Uint256(1, 0), 3, pixel_colorizations
    );

    let (count) = IRtwrkDrawer.numberOfPixelColorizations(
        rtwrk_drawer_contract_address, ORIGINAL_RTWRKS_COUNT + 1, Uint256(1, 0)
    );
    let (count_total) = IRtwrkDrawer.totalNumberOfPixelColorizations(
        rtwrk_drawer_contract_address, ORIGINAL_RTWRKS_COUNT + 1
    );
    assert 3 = count;
    assert 3 = count_total;

    let (pixel_colorizations: PixelColorization*) = alloc();
    assert pixel_colorizations[0] = PixelColorization(pixel_index=399, color_index=94);
    assert pixel_colorizations[1] = PixelColorization(pixel_index=128, color_index=85);
    assert pixel_colorizations[2] = PixelColorization(pixel_index=36, color_index=2);
    assert pixel_colorizations[3] = PixelColorization(pixel_index=360, color_index=78);
    assert pixel_colorizations[4] = PixelColorization(pixel_index=220, color_index=57);
    assert pixel_colorizations[5] = PixelColorization(pixel_index=48, color_index=32);
    assert pixel_colorizations[6] = PixelColorization(pixel_index=178, color_index=90);
    assert pixel_colorizations[7] = PixelColorization(pixel_index=300, color_index=12);
    assert pixel_colorizations[8] = PixelColorization(pixel_index=27, color_index=18);
    assert pixel_colorizations[9] = PixelColorization(pixel_index=82, color_index=92);
    IRtwrkDrawer.colorizePixels(
        rtwrk_drawer_contract_address, Uint256(2, 0), 10, pixel_colorizations
    );

    // 10 colorizations that will be batched in 2 felts

    let (count_1) = IRtwrkDrawer.numberOfPixelColorizations(
        rtwrk_drawer_contract_address, ORIGINAL_RTWRKS_COUNT + 1, Uint256(1, 0)
    );
    let (count_2) = IRtwrkDrawer.numberOfPixelColorizations(
        rtwrk_drawer_contract_address, ORIGINAL_RTWRKS_COUNT + 1, Uint256(2, 0)
    );
    let (count_total) = IRtwrkDrawer.totalNumberOfPixelColorizations(
        rtwrk_drawer_contract_address, ORIGINAL_RTWRKS_COUNT + 1
    );
    assert 3 = count;
    assert 10 = count_2;
    assert 13 = count_total;

    %{ stop_prank_drawer() %}
    return ();
}

@view
func test_rtwrk_drawer_original_rtwrks{
    syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}() {
    alloc_locals;

    local rtwrk_drawer_contract_address;
    %{ ids.rtwrk_drawer_contract_address = context.rtwrk_drawer_contract_address %}

    let (rtwrk_id) = IRtwrkDrawer.currentRtwrkId(contract_address=rtwrk_drawer_contract_address);
    assert ORIGINAL_RTWRKS_COUNT + 1 = rtwrk_id;

    // Verify that we're able to get original rtwrks from dw data

    let (grid_1_len: felt, grid_1: felt*) = IRtwrkDrawer.rtwrkGrid(
        contract_address=rtwrk_drawer_contract_address, rtwrkId=1, rtwrkStep=0
    );

    let (grid_2_len: felt, grid_2: felt*) = IRtwrkDrawer.rtwrkGrid(
        contract_address=rtwrk_drawer_contract_address, rtwrkId=2, rtwrkStep=0
    );
    let (grid_7_final_len: felt, grid_7_final: felt*) = IRtwrkDrawer.rtwrkGrid(
        contract_address=rtwrk_drawer_contract_address, rtwrkId=7, rtwrkStep=0
    );
    let (
        grid_7_intermediate_109_len: felt, grid_7_intermediate_109: felt*
    ) = IRtwrkDrawer.rtwrkGrid(
        contract_address=rtwrk_drawer_contract_address, rtwrkId=7, rtwrkStep=109
    );
    let (grid_7_intermediate_4_len: felt, grid_7_intermediate_4: felt*) = IRtwrkDrawer.rtwrkGrid(
        contract_address=rtwrk_drawer_contract_address, rtwrkId=7, rtwrkStep=4
    );

    // Length is # of pixel * 4 (see PixelColor struct)
    assert 20 * 20 * 4 = grid_1_len;
    assert 20 * 20 * 4 = grid_2_len;
    assert 20 * 20 * 4 = grid_7_final_len;
    assert 20 * 20 * 4 = grid_7_intermediate_109_len;
    assert 20 * 20 * 4 = grid_7_intermediate_4_len;

    assert TRUE = grid_1[0];
    assert 211 = grid_1[1];
    assert 47 = grid_1[2];
    assert 47 = grid_1[3];

    assert TRUE = grid_1[399 * 4];
    assert 255 = grid_1[399 * 4 + 1];
    assert 255 = grid_1[399 * 4 + 2];
    assert 255 = grid_1[399 * 4 + 3];

    assert FALSE = grid_1[1 * 4];
    assert 0 = grid_1[1 * 4 + 1];
    assert 0 = grid_1[1 * 4 + 2];
    assert 0 = grid_1[1 * 4 + 3];

    assert TRUE = grid_1[3 * 4];
    assert 233 = grid_1[3 * 4 + 1];
    assert 30 = grid_1[3 * 4 + 2];
    assert 99 = grid_1[3 * 4 + 3];

    assert TRUE = grid_2[0];
    assert 242 = grid_2[1];
    assert 242 = grid_2[2];
    assert 242 = grid_2[3];

    assert TRUE = grid_2[5 * 4];
    assert 26 = grid_2[5 * 4 + 1];
    assert 35 = grid_2[5 * 4 + 2];
    assert 126 = grid_2[5 * 4 + 3];

    assert TRUE = grid_2[395 * 4];
    assert 26 = grid_2[395 * 4 + 1];
    assert 35 = grid_2[395 * 4 + 2];
    assert 126 = grid_2[395 * 4 + 3];

    assert TRUE = grid_2[399 * 4];
    assert 242 = grid_2[399 * 4 + 1];
    assert 242 = grid_2[399 * 4 + 2];
    assert 242 = grid_2[399 * 4 + 3];

    // Pixel 19 of rtwrk 7 is non colored at step 4,
    // black at step 109, orange (255,111,0) at final step

    assert FALSE = grid_7_intermediate_4[18 * 4];
    assert 0 = grid_7_intermediate_4[18 * 4 + 1];
    assert 0 = grid_7_intermediate_4[18 * 4 + 2];
    assert 0 = grid_7_intermediate_4[18 * 4 + 3];

    assert TRUE = grid_7_intermediate_109[18 * 4];
    assert 0 = grid_7_intermediate_109[18 * 4 + 1];
    assert 0 = grid_7_intermediate_109[18 * 4 + 2];
    assert 0 = grid_7_intermediate_109[18 * 4 + 3];

    assert TRUE = grid_7_final[18 * 4];
    assert 255 = grid_7_final[18 * 4 + 1];
    assert 111 = grid_7_final[18 * 4 + 2];
    assert 0 = grid_7_final[18 * 4 + 3];

    return ();
}
