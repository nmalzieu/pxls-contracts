%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.alloc import alloc

from pxls.RtwrkDrawer.colorization import PixelColorization, Colorization, save_rtwrk_colorization
from pxls.RtwrkDrawer.original_rtwrks import ORIGINAL_RTWRKS_COUNT

from pxls.RtwrkDrawer.grid import get_grid
from pxls.RtwrkDrawer.token_uri import get_rtwrk_token_uri
from pxls.interfaces import IPxlERC721, IRtwrkDrawer

@view
func __setup__{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}() {
    alloc_locals;
    let name = 'Pixel';
    let symbol = 'PXL';

    %{
        from starkware.starknet.public.abi import get_selector_from_name
        context.account = 123456
    %}

    // Data contracts are heavy, deploying just a sample
    %{ context.sample_pxl_metadata_address = deploy_contract("tests/sample_pxl_metadata_contract.cairo", []).contract_address %}

    %{
        # Let's deploy the Pxl ERC721 with proxy pattern
        pxl_erc721_hash = declare("contracts/pxls/PxlERC721/PxlERC721.cairo").class_hash
        context.pxl_erc721_contract_address = deploy_contract("contracts/pxls/Proxy.cairo", {
            "implementation_hash": pxl_erc721_hash,
            "selector": get_selector_from_name("initializer"),
            "calldata": [
                context.account, # proxy_admin
                ids.name, # name
                ids.symbol, # symbol
                20, # m_size.low
                0, # m_size.high
                context.account, # owner
                context.sample_pxl_metadata_address, # pxls_1_100_address
                context.sample_pxl_metadata_address, # pxls_101_200_address
                context.sample_pxl_metadata_address, # pxls_201_300_address
                context.sample_pxl_metadata_address  # pxls_301_400_address
            ]
        }).contract_address
    %}

    %{
        # Let's deploy the drawer contract with proxy pattern
        rtwrk_drawer_hash = declare("contracts/pxls/RtwrkDrawer/RtwrkDrawer.cairo").class_hash
        context.rtwrk_drawer_contract_address = deploy_contract("contracts/pxls/Proxy.cairo", {
            "implementation_hash": rtwrk_drawer_hash,
            "selector": get_selector_from_name("initializer"),
            "calldata": [
                context.account, # proxy_admin
                context.account, # owner
                context.pxl_erc721_contract_address, # pxl_erc721
            ]
        }).contract_address
    %}

    %{ stop_prank_pixel = start_prank(context.account, target_contract_address=context.pxl_erc721_contract_address) %}
    %{ stop_prank_drawer = start_prank(context.account, target_contract_address=context.rtwrk_drawer_contract_address) %}

    local pxl_erc721_contract_address;
    %{ ids.pxl_erc721_contract_address = context.pxl_erc721_contract_address %}

    local rtwrk_drawer_contract_address;
    %{ ids.rtwrk_drawer_contract_address = context.rtwrk_drawer_contract_address %}

    IPxlERC721.mint(contract_address=pxl_erc721_contract_address, to=123456);
    IPxlERC721.mint(contract_address=pxl_erc721_contract_address, to=123457);

    // Warping time before launching the initial rtwrk
    let start_timestamp = 'start_timestamp';
    %{ warp(ids.start_timestamp, context.rtwrk_drawer_contract_address) %}

    let (theme: felt*) = alloc();
    assert theme[0] = 'Super theme';

    // Only auction contract can launch an rtwrk, let's fake it
    %{ store(context.rtwrk_drawer_contract_address, "rtwrk_auction_address", [context.account]) %}

    // Launching the initial rtwrk
    IRtwrkDrawer.launchNewRtwrk(
        contract_address=rtwrk_drawer_contract_address,
        theme_len=1,
        theme=theme,
        auction_winner=123456,
        auction_bid_amount=Uint256(5000000000000000, 0),
    );

    %{ stop_prank_pixel() %}

    // 99 persons colorize 20 pixels in 20 transactions of 1 colorization = 1980 colorizations < MAX

    %{
        import random
        colorization_index = 0
        # Keeping token 1 & 2 without colorizations to test max colorizations
        for token_id in range(3, 102):
            for i in range(20):
                pixel_index = random.randrange(400)
                color_index = random.randrange(95)
                colorization_packed = (pixel_index * 95 + color_index) * 400 + token_id
                store(context.rtwrk_drawer_contract_address, "rtwrk_colorizations", [colorization_packed], key=[ids.ORIGINAL_RTWRKS_COUNT + 1,colorization_index])
                colorization_index += 1
            store(context.rtwrk_drawer_contract_address, "number_of_pixel_colorizations_per_colorizer", [20], key=[ids.ORIGINAL_RTWRKS_COUNT + 1,token_id,0])
        store(context.rtwrk_drawer_contract_address, "rtwrk_colorization_index", [colorization_index], key=[ids.ORIGINAL_RTWRKS_COUNT + 1])
        store(context.rtwrk_drawer_contract_address, "number_of_pixel_colorizations_total", [1980], key=[ids.ORIGINAL_RTWRKS_COUNT + 1])
    %}

    // 99 persons colorize 20 pixels in 1 transactions of 20 colorization = 1980 colorizations < MAX
    // Colorizations are stored 8 by 8 (8 fit in a single felt)

    %{
        import random
        colorization_index = 0
        # Keeping token 1 & 2 without colorizations to test max colorizations
        for token_id in range(3, 102):
            pixel_colorizations_packed = 0
            for i in range(20):
                pixel_index = random.randrange(400)
                color_index = random.randrange(95)
                pixel_colorization_packed = pixel_index * 95 + color_index
                pixel_colorizations_packed = pixel_colorizations_packed * 38000 + pixel_colorization_packed
                if (i + 1) % 8 == 0:
                    colorization_packed = pixel_colorizations_packed * 400 + token_id
                    store(context.rtwrk_drawer_contract_address, "rtwrk_colorizations", [colorization_packed], key=[ids.ORIGINAL_RTWRKS_COUNT + 2,colorization_index])
                    colorization_index += 1
                    pixel_colorizations_packed = 0
            if pixel_colorizations_packed != 0:
                colorization_packed = pixel_colorizations_packed * 400 + token_id
                store(context.rtwrk_drawer_contract_address, "rtwrk_colorizations", [colorization_packed], key=[ids.ORIGINAL_RTWRKS_COUNT + 2,colorization_index])
            store(context.rtwrk_drawer_contract_address, "number_of_pixel_colorizations_per_colorizer", [20], key=[ids.ORIGINAL_RTWRKS_COUNT + 2,token_id,0])
        store(context.rtwrk_drawer_contract_address, "rtwrk_colorization_index", [colorization_index], key=[ids.ORIGINAL_RTWRKS_COUNT + 2])
        store(context.rtwrk_drawer_contract_address, "number_of_pixel_colorizations_total", [1980], key=[ids.ORIGINAL_RTWRKS_COUNT + 2])
    %}

    %{ stop_prank_drawer() %}

    return ();
}

@view
func test_get_grid_1_by_1{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}() {
    alloc_locals;

    local rtwrk_drawer_contract_address;
    %{ ids.rtwrk_drawer_contract_address = context.rtwrk_drawer_contract_address %}
    let (grid_len: felt, grid: felt*) = IRtwrkDrawer.rtwrkGrid(
        contract_address=rtwrk_drawer_contract_address,
        rtwrkId=ORIGINAL_RTWRKS_COUNT + 1,
        rtwrkStep=0,
    );
    return ();
}

@view
func test_get_grid_20_by_20{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}() {
    alloc_locals;

    // Warping time before launching the second rtwrk
    let new_timestamp = 'start_timestamp' + (26 * 3600 + 136);
    %{ warp(ids.new_timestamp, context.rtwrk_drawer_contract_address) %}

    // Fake rtwrk 2
    %{
        store(context.rtwrk_drawer_contract_address, "current_rtwrk_id", [ids.ORIGINAL_RTWRKS_COUNT + 2])
        store(context.rtwrk_drawer_contract_address, "rtwrk_timestamp", [ids.new_timestamp], key=[ids.ORIGINAL_RTWRKS_COUNT + 2])
    %}

    local rtwrk_drawer_contract_address;
    %{ ids.rtwrk_drawer_contract_address = context.rtwrk_drawer_contract_address %}
    let (grid_len: felt, grid: felt*) = IRtwrkDrawer.rtwrkGrid(
        contract_address=rtwrk_drawer_contract_address,
        rtwrkId=ORIGINAL_RTWRKS_COUNT + 2,
        rtwrkStep=0,
    );
    return ();
}

@view
func test_get_grid_and_generate_token_uri{
    syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}() {
    alloc_locals;

    local rtwrk_drawer_contract_address;
    %{ ids.rtwrk_drawer_contract_address = context.rtwrk_drawer_contract_address %}
    let (grid_len: felt, grid: felt*) = IRtwrkDrawer.rtwrkGrid(
        contract_address=rtwrk_drawer_contract_address,
        rtwrkId=ORIGINAL_RTWRKS_COUNT + 1,
        rtwrkStep=0,
    );

    let (token_uri_len: felt, token_uri: felt*) = get_rtwrk_token_uri(
        20, ORIGINAL_RTWRKS_COUNT + 1, grid_len, grid
    );

    return ();
}

@view
func test_colorize_1_by_1{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}() {
    alloc_locals;

    local rtwrk_drawer_contract_address;
    %{ ids.rtwrk_drawer_contract_address = context.rtwrk_drawer_contract_address %}

    %{ stop_prank_drawer = start_prank(context.account, target_contract_address=context.rtwrk_drawer_contract_address) %}
    let (pixel_colorizations: PixelColorization*) = alloc();
    assert pixel_colorizations[0] = PixelColorization(pixel_index=12, color_index=92);
    assert pixel_colorizations[1] = PixelColorization(pixel_index=18, color_index=3);
    assert pixel_colorizations[2] = PixelColorization(pixel_index=1, color_index=12);

    IRtwrkDrawer.colorizePixels(
        rtwrk_drawer_contract_address, Uint256(1, 0), 3, pixel_colorizations
    );
    %{ stop_prank_drawer() %}
    return ();
}

@view
func test_colorize_20_by_20{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}() {
    alloc_locals;

    // Warping time before launching the second rtwrk
    let new_timestamp = 'start_timestamp' + (26 * 3600 + 136);
    %{ warp(ids.new_timestamp, context.rtwrk_drawer_contract_address) %}

    // Fake rtwrk 2
    %{
        store(context.rtwrk_drawer_contract_address, "current_rtwrk_id", [ids.ORIGINAL_RTWRKS_COUNT+2])
        store(context.rtwrk_drawer_contract_address, "rtwrk_timestamp", [ids.new_timestamp], key=[ids.ORIGINAL_RTWRKS_COUNT+2])
    %}

    local rtwrk_drawer_contract_address;
    %{ ids.rtwrk_drawer_contract_address = context.rtwrk_drawer_contract_address %}

    %{ stop_prank_drawer = start_prank(context.account, target_contract_address=context.rtwrk_drawer_contract_address) %}
    let (pixel_colorizations: PixelColorization*) = alloc();
    assert pixel_colorizations[0] = PixelColorization(pixel_index=12, color_index=92);
    assert pixel_colorizations[1] = PixelColorization(pixel_index=18, color_index=3);
    assert pixel_colorizations[2] = PixelColorization(pixel_index=1, color_index=12);

    IRtwrkDrawer.colorizePixels(
        rtwrk_drawer_contract_address, Uint256(1, 0), 3, pixel_colorizations
    );
    %{ stop_prank_drawer() %}
    return ();
}

@view
func test_colorize_hit_limit_1_by_1{
    syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}() {
    alloc_locals;

    local rtwrk_drawer_contract_address;
    %{ ids.rtwrk_drawer_contract_address = context.rtwrk_drawer_contract_address %}

    %{ stop_prank_drawer = start_prank(context.account, target_contract_address=context.rtwrk_drawer_contract_address) %}

    // Adding 20 more pixel colorizations for pxl 1 => brings total to 2000 which is max!
    let (pixel_colorizations: PixelColorization*) = alloc();
    assert pixel_colorizations[0] = PixelColorization(pixel_index=12, color_index=92);
    assert pixel_colorizations[1] = PixelColorization(pixel_index=18, color_index=3);
    assert pixel_colorizations[2] = PixelColorization(pixel_index=1, color_index=12);
    assert pixel_colorizations[3] = PixelColorization(pixel_index=12, color_index=92);
    assert pixel_colorizations[4] = PixelColorization(pixel_index=18, color_index=3);
    assert pixel_colorizations[5] = PixelColorization(pixel_index=1, color_index=12);
    assert pixel_colorizations[6] = PixelColorization(pixel_index=12, color_index=92);
    assert pixel_colorizations[7] = PixelColorization(pixel_index=18, color_index=3);
    assert pixel_colorizations[8] = PixelColorization(pixel_index=1, color_index=12);
    assert pixel_colorizations[9] = PixelColorization(pixel_index=1, color_index=12);
    assert pixel_colorizations[10] = PixelColorization(pixel_index=12, color_index=92);
    assert pixel_colorizations[11] = PixelColorization(pixel_index=18, color_index=3);
    assert pixel_colorizations[12] = PixelColorization(pixel_index=1, color_index=12);
    assert pixel_colorizations[13] = PixelColorization(pixel_index=12, color_index=92);
    assert pixel_colorizations[14] = PixelColorization(pixel_index=18, color_index=3);
    assert pixel_colorizations[15] = PixelColorization(pixel_index=1, color_index=12);
    assert pixel_colorizations[16] = PixelColorization(pixel_index=12, color_index=92);
    assert pixel_colorizations[17] = PixelColorization(pixel_index=18, color_index=3);
    assert pixel_colorizations[18] = PixelColorization(pixel_index=1, color_index=12);
    assert pixel_colorizations[19] = PixelColorization(pixel_index=1, color_index=12);

    IRtwrkDrawer.colorizePixels(
        rtwrk_drawer_contract_address, Uint256(1, 0), 20, pixel_colorizations
    );
    %{ stop_prank_drawer() %}

    let (total_pixel_colorizations_count) = IRtwrkDrawer.totalNumberOfPixelColorizations(
        rtwrk_drawer_contract_address, ORIGINAL_RTWRKS_COUNT + 1
    );
    assert 2000 = total_pixel_colorizations_count;

    let (max_total) = IRtwrkDrawer.totalNumberOfPixelColorizations(
        rtwrk_drawer_contract_address, ORIGINAL_RTWRKS_COUNT + 1
    );
    assert 2000 = total_pixel_colorizations_count;

    %{ stop_prank_drawer = start_prank(123457, target_contract_address=context.rtwrk_drawer_contract_address) %}

    %{ expect_revert(error_message="The max total number of allowed colorizations for this rtwrk has been reached") %}
    // Sending just one colorization should fail because we hit the 2000 hard limit
    IRtwrkDrawer.colorizePixels(
        rtwrk_drawer_contract_address, Uint256(2, 0), 1, pixel_colorizations
    );

    %{ stop_prank_drawer() %}
    return ();
}

@view
func test_colorize_hit_limit_20_by_20{
    syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}() {
    alloc_locals;

    local rtwrk_drawer_contract_address;
    %{ ids.rtwrk_drawer_contract_address = context.rtwrk_drawer_contract_address %}

    // Warping time before launching the second rtwrk
    let new_timestamp = 'start_timestamp' + (26 * 3600 + 136);
    %{ warp(ids.new_timestamp, context.rtwrk_drawer_contract_address) %}

    // Fake rtwrk 2
    %{
        store(context.rtwrk_drawer_contract_address, "current_rtwrk_id", [ids.ORIGINAL_RTWRKS_COUNT+2])
        store(context.rtwrk_drawer_contract_address, "rtwrk_timestamp", [ids.new_timestamp], key=[ids.ORIGINAL_RTWRKS_COUNT+2])
    %}

    %{ stop_prank_drawer = start_prank(context.account, target_contract_address=context.rtwrk_drawer_contract_address) %}
    let (pixel_colorizations: PixelColorization*) = alloc();
    assert pixel_colorizations[0] = PixelColorization(pixel_index=12, color_index=92);
    assert pixel_colorizations[1] = PixelColorization(pixel_index=18, color_index=3);
    assert pixel_colorizations[2] = PixelColorization(pixel_index=1, color_index=12);
    assert pixel_colorizations[3] = PixelColorization(pixel_index=12, color_index=92);
    assert pixel_colorizations[4] = PixelColorization(pixel_index=18, color_index=3);
    assert pixel_colorizations[5] = PixelColorization(pixel_index=1, color_index=12);
    assert pixel_colorizations[6] = PixelColorization(pixel_index=12, color_index=92);
    assert pixel_colorizations[7] = PixelColorization(pixel_index=18, color_index=3);
    assert pixel_colorizations[8] = PixelColorization(pixel_index=1, color_index=12);
    assert pixel_colorizations[9] = PixelColorization(pixel_index=1, color_index=12);
    assert pixel_colorizations[10] = PixelColorization(pixel_index=12, color_index=92);
    assert pixel_colorizations[11] = PixelColorization(pixel_index=18, color_index=3);
    assert pixel_colorizations[12] = PixelColorization(pixel_index=1, color_index=12);
    assert pixel_colorizations[13] = PixelColorization(pixel_index=12, color_index=92);
    assert pixel_colorizations[14] = PixelColorization(pixel_index=18, color_index=3);
    assert pixel_colorizations[15] = PixelColorization(pixel_index=1, color_index=12);
    assert pixel_colorizations[16] = PixelColorization(pixel_index=12, color_index=92);
    assert pixel_colorizations[17] = PixelColorization(pixel_index=18, color_index=3);
    assert pixel_colorizations[18] = PixelColorization(pixel_index=1, color_index=12);
    assert pixel_colorizations[19] = PixelColorization(pixel_index=1, color_index=12);

    IRtwrkDrawer.colorizePixels(
        rtwrk_drawer_contract_address, Uint256(1, 0), 20, pixel_colorizations
    );
    %{ stop_prank_drawer() %}

    %{ stop_prank_drawer = start_prank(123457, target_contract_address=context.rtwrk_drawer_contract_address) %}

    %{ expect_revert(error_message="The max total number of allowed colorizations for this rtwrk has been reached") %}
    // Sending just one colorization should fail because we hit the 2000 hard limit
    IRtwrkDrawer.colorizePixels(
        rtwrk_drawer_contract_address, Uint256(2, 0), 1, pixel_colorizations
    );

    %{ stop_prank_drawer() %}
    return ();
}

@view
func test_get_colorizers_1_by_1{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}() {
    alloc_locals;

    local rtwrk_drawer_contract_address;
    %{ ids.rtwrk_drawer_contract_address = context.rtwrk_drawer_contract_address %}
    let (count: felt) = IRtwrkDrawer.numberOfColorizers(
        contract_address=rtwrk_drawer_contract_address,
        rtwrkId=ORIGINAL_RTWRKS_COUNT + 1,
        rtwrkStep=0,
    );
    assert 99 = count;
    return ();
}

@view
func test_get_colorizers_20_by_20{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}(
    ) {
    alloc_locals;

    // Warping time before launching the second rtwrk
    let new_timestamp = 'start_timestamp' + (26 * 3600 + 136);
    %{ warp(ids.new_timestamp, context.rtwrk_drawer_contract_address) %}

    // Fake rtwrk 2
    %{
        store(context.rtwrk_drawer_contract_address, "current_rtwrk_id", [ids.ORIGINAL_RTWRKS_COUNT+2])
        store(context.rtwrk_drawer_contract_address, "rtwrk_timestamp", [ids.new_timestamp], key=[ids.ORIGINAL_RTWRKS_COUNT+2])
    %}

    local rtwrk_drawer_contract_address;
    %{ ids.rtwrk_drawer_contract_address = context.rtwrk_drawer_contract_address %}
    let (count: felt) = IRtwrkDrawer.numberOfColorizers(
        contract_address=rtwrk_drawer_contract_address,
        rtwrkId=ORIGINAL_RTWRKS_COUNT + 2,
        rtwrkStep=0,
    );
    assert 99 = count;
    return ();
}

@view
func test_number_colorizations_1_by_1{
    syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}() {
    alloc_locals;

    local rtwrk_drawer_contract_address;
    %{ ids.rtwrk_drawer_contract_address = context.rtwrk_drawer_contract_address %}
    let (count: felt) = IRtwrkDrawer.numberOfPixelColorizations(
        contract_address=rtwrk_drawer_contract_address,
        rtwrkId=ORIGINAL_RTWRKS_COUNT + 1,
        pxlId=Uint256(3, 0),
    );
    assert 20 = count;
    return ();
}

@view
func test_number_colorizations_20_by_20{
    syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}() {
    alloc_locals;

    // Warping time before launching the second rtwrk
    let new_timestamp = 'start_timestamp' + (26 * 3600 + 136);
    %{ warp(ids.new_timestamp, context.rtwrk_drawer_contract_address) %}

    // Fake rtwrk 2
    %{
        store(context.rtwrk_drawer_contract_address, "current_rtwrk_id", [ids.ORIGINAL_RTWRKS_COUNT+2])
        store(context.rtwrk_drawer_contract_address, "rtwrk_timestamp", [ids.new_timestamp], key=[ids.ORIGINAL_RTWRKS_COUNT+2])
    %}

    local rtwrk_drawer_contract_address;
    %{ ids.rtwrk_drawer_contract_address = context.rtwrk_drawer_contract_address %}
    let (count: felt) = IRtwrkDrawer.numberOfPixelColorizations(
        contract_address=rtwrk_drawer_contract_address,
        rtwrkId=ORIGINAL_RTWRKS_COUNT + 2,
        pxlId=Uint256(3, 0),
    );
    assert 20 = count;
    return ();
}
