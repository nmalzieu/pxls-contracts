%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.alloc import alloc

from openzeppelin.token.erc20.IERC20 import IERC20
from caistring.str import literal_from_number

from pxls.interfaces import IRtwrkERC721, IRtwrkDrawer, IRtwrkThemeAuction
from pxls.RtwrkDrawer.original_rtwrks import ORIGINAL_RTWRKS_COUNT
from pxls.RtwrkThemeAuction.variables import BID_INCREMENT
from pxls.RtwrkDrawer.colorization import PixelColorization

@view
func __setup__{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}() {
    %{ context.account = 123456 %}

    // Deploy an ETH ERC 20

    %{
        context.eth_erc_20_contract_address = deploy_contract("contracts/openzeppelin/token/erc20/presets/ERC20.cairo", {
               "name": "Ether",
               "symbol": "ETH",
               "decimals": 18,
               "initial_supply": 100000000000000000000,
               "recipient": 1212
           }).contract_address
    %}

    // Deploy the PXL NFT contract

    let pxl_name = 'Pixel';
    let pxl_symbol = 'PXL';

    %{
        context.pxl_erc721_contract_address = deploy_contract("contracts/pxls/PxlERC721/PxlERC721.cairo", [
            ids.pxl_name,
            ids.pxl_symbol,
            20,
            0,
            context.account,
            0,
            0,
            0,
            0
        ]).contract_address
    %}

    // Deploy the drawer contract

    %{ context.rtwrk_drawer_contract_address = deploy_contract("contracts/pxls/RtwrkDrawer/RtwrkDrawer.cairo", [context.account, context.pxl_erc721_contract_address]).contract_address %}

    // Deploy the Rtwrk ERC721 contract

    %{
        context.rtwrk_erc721_contract_address = deploy_contract("contracts/pxls/RtwrkERC721/RtwrkERC721.cairo", {
               "owner": context.account,
               "rtwrk_drawer_address_value": context.rtwrk_drawer_contract_address,
           }).contract_address
    %}

    // Deploy the auction contract

    %{
        context.auction_contract_address = deploy_contract("contracts/pxls/RtwrkThemeAuction/RtwrkThemeAuction.cairo", {
               "owner": context.account,
               "eth_erc20_address_value": context.eth_erc_20_contract_address,
               "pxls_erc721_address_value": context.pxl_erc721_contract_address,
               "rtwrk_drawer_address_value":  context.rtwrk_drawer_contract_address,
               "rtwrk_erc721_address_value": context.rtwrk_erc721_contract_address,
           }).contract_address
    %}

    // Set the auction contract address in the ERC721 contract

    tempvar rtwrk_erc721_contract_address;
    %{ ids.rtwrk_erc721_contract_address = context.rtwrk_erc721_contract_address %}

    tempvar auction_contract_address;
    %{ ids.auction_contract_address = context.auction_contract_address %}

    tempvar rtwrk_drawer_contract_address;
    %{ ids.rtwrk_drawer_contract_address = context.rtwrk_drawer_contract_address %}

    %{ stop_prank_rtwrk_erc721 = start_prank(context.account, target_contract_address=context.rtwrk_erc721_contract_address) %}

    IRtwrkERC721.setRtwrkThemeAuctionContractAddress(
        rtwrk_erc721_contract_address, auction_contract_address
    );

    %{ stop_prank_rtwrk_erc721 () %}

    %{ stop_prank_rtwrk_drawer = start_prank(context.account, target_contract_address=context.rtwrk_drawer_contract_address) %}

    IRtwrkDrawer.setRtwrkThemeAuctionContractAddress(
        rtwrk_drawer_contract_address, auction_contract_address
    );

    %{ stop_prank_rtwrk_drawer () %}

    return ();
}

@view
func test_rtwrk_erc721_getters{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}() {
    tempvar rtwrk_erc721_contract_address;
    %{ ids.rtwrk_erc721_contract_address = context.rtwrk_erc721_contract_address %}

    tempvar auction_contract_address;
    %{ ids.auction_contract_address = context.auction_contract_address %}

    let (exists) = IRtwrkERC721.exists(rtwrk_erc721_contract_address, Uint256(1, 0));
    assert TRUE = exists;

    // First NFTs are minted to the owner
    let (ownerOfToken) = IRtwrkERC721.ownerOf(
        rtwrk_erc721_contract_address, Uint256(ORIGINAL_RTWRKS_COUNT, 0)
    );
    assert 123456 = ownerOfToken;

    let (auction_contract_address_in_rtwrk_erc721) = IRtwrkERC721.rtwrkThemeAuctionContractAddress(
        rtwrk_erc721_contract_address
    );
    assert auction_contract_address = auction_contract_address_in_rtwrk_erc721;

    return ();
}

@view
func test_rtwrk_erc721_contract_uri{
    syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}() {
    alloc_locals;

    local rtwrk_erc721_contract_address;
    %{ ids.rtwrk_erc721_contract_address = context.rtwrk_erc721_contract_address %}

    let (contract_uri_len: felt, contract_uri: felt*) = IRtwrkERC721.contractURI(
        contract_address=rtwrk_erc721_contract_address
    );
    assert 4 = contract_uri_len;
    assert 'ipfs://' = contract_uri[0];
    assert 0 = contract_uri[1];
    assert 0 = contract_uri[2];
    assert 0 = contract_uri[3];

    let (hash: felt*) = alloc();
    assert hash[0] = 'vez2qw8z6poiozzgjqnbapzcekb4h8j';
    assert hash[1] = 'hsiuxvjaqqb4e6p0synfwnxobnes6m7';
    assert hash[2] = 'j66w';

    %{ stop_prank_rtwrk_erc721 = start_prank(context.account, target_contract_address=context.rtwrk_erc721_contract_address) %}

    IRtwrkERC721.setContractURIHash(
        contract_address=rtwrk_erc721_contract_address, hash_len=3, hash=hash
    );
    let (contract_uri_len: felt, contract_uri: felt*) = IRtwrkERC721.contractURI(
        contract_address=rtwrk_erc721_contract_address
    );
    assert 4 = contract_uri_len;
    assert 'ipfs://' = contract_uri[0];
    assert 'vez2qw8z6poiozzgjqnbapzcekb4h8j' = contract_uri[1];
    assert 'hsiuxvjaqqb4e6p0synfwnxobnes6m7' = contract_uri[2];
    assert 'j66w' = contract_uri[3];

    %{ stop_prank_rtwrk_erc721() %}

    // Verify that only owner can set contract uri hash
    %{ expect_revert(error_message="Ownable: caller is not the owner") %}
    IRtwrkERC721.setContractURIHash(
        contract_address=rtwrk_erc721_contract_address, hash_len=3, hash=hash
    );

    return ();
}

@view
func test_rtwrk_erc721_set_auction_address{
    syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}() {
    tempvar auction_contract_address;
    %{ ids.auction_contract_address = context.auction_contract_address %}

    tempvar rtwrk_erc721_contract_address;
    %{ ids.rtwrk_erc721_contract_address = context.rtwrk_erc721_contract_address %}

    let (current_auction_address) = IRtwrkERC721.rtwrkThemeAuctionContractAddress(
        rtwrk_erc721_contract_address
    );
    assert auction_contract_address = current_auction_address;

    %{ stop_prank = start_prank(context.account, target_contract_address=context.rtwrk_erc721_contract_address) %}
    IRtwrkERC721.setRtwrkThemeAuctionContractAddress(rtwrk_erc721_contract_address, 12);

    let (new_auction_address) = IRtwrkERC721.rtwrkThemeAuctionContractAddress(
        rtwrk_erc721_contract_address
    );
    assert 12 = new_auction_address;

    %{ stop_prank() %}

    %{ expect_revert(error_message="Ownable: caller is not the owner") %}
    IRtwrkERC721.setRtwrkThemeAuctionContractAddress(rtwrk_erc721_contract_address, 12);
    return ();
}

@view
func test_launch_auction{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}() {
    alloc_locals;
    local rtwrk_drawer_contract_address;
    %{ ids.rtwrk_drawer_contract_address = context.rtwrk_drawer_contract_address %}

    local auction_contract_address;
    %{ ids.auction_contract_address = context.auction_contract_address %}

    // Verify no auction at beginning
    let (current_auction_id) = IRtwrkThemeAuction.currentAuctionId(auction_contract_address);
    assert 0 = current_auction_id;

    // Let's launch an auction
    launch_auction(1667048630);

    let (current_auction_id) = IRtwrkThemeAuction.currentAuctionId(auction_contract_address);
    assert 1 = current_auction_id;

    let (current_auction_timestamp) = IRtwrkThemeAuction.auctionTimestamp(
        auction_contract_address, 1
    );
    assert 1667048630 = current_auction_timestamp;

    %{ expect_revert(error_message="Cannot call this method while an auction is running"); %}
    launch_auction(1667048635);

    return ();
}

@view
func test_place_bid_no_money{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}() {
    alloc_locals;
    local rtwrk_drawer_contract_address;
    %{ ids.rtwrk_drawer_contract_address = context.rtwrk_drawer_contract_address %}

    local auction_contract_address;
    %{ ids.auction_contract_address = context.auction_contract_address %}

    launch_auction(1667048630);

    // Verify no bids at first
    let (bids_count) = IRtwrkThemeAuction.auctionBidsCount(auction_contract_address, 1);
    assert 0 = bids_count;

    // We haven't allowed the auction contract to get money from us

    %{ expect_revert(error_message="ERC20: transfer amount exceeds balance") %}

    let (bid_theme_1: felt*) = alloc();
    assert bid_theme_1[0] = 'Super theme';
    assert bid_theme_1[1] = 'is this theme';

    place_bid(
        auction_id=1,
        account=1515,
        amount=5000000000000000,
        timestamp=1667048632,
        theme_len=2,
        theme=bid_theme_1,
    );

    return ();
}

@view
func test_place_bid_after_auction{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}(
    ) {
    alloc_locals;
    local rtwrk_drawer_contract_address;
    %{ ids.rtwrk_drawer_contract_address = context.rtwrk_drawer_contract_address %}

    local auction_contract_address;
    %{ ids.auction_contract_address = context.auction_contract_address %}

    local eth_erc_20_contract_address;
    %{ ids.eth_erc_20_contract_address = context.eth_erc_20_contract_address %}

    launch_auction(1667048630);

    let (bid_theme_1: felt*) = alloc();
    assert bid_theme_1[0] = 'Super theme';
    assert bid_theme_1[1] = 'is this theme';

    %{ expect_revert(error_message="There is currently no running auction") %}

    place_bid(
        auction_id=1,
        account=1212,
        amount=5000000000000000,
        timestamp=1667048632 + 26 * 3600,
        theme_len=2,
        theme=bid_theme_1,
    );

    return ();
}

@view
func test_place_bid{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}() {
    alloc_locals;
    local rtwrk_drawer_contract_address;
    %{ ids.rtwrk_drawer_contract_address = context.rtwrk_drawer_contract_address %}

    local auction_contract_address;
    %{ ids.auction_contract_address = context.auction_contract_address %}

    local eth_erc_20_contract_address;
    %{ ids.eth_erc_20_contract_address = context.eth_erc_20_contract_address %}

    launch_auction(1667048630);

    // Verify no bids at first
    let (bids_count) = IRtwrkThemeAuction.auctionBidsCount(auction_contract_address, 1);
    assert 0 = bids_count;

    let (bid_theme_1: felt*) = alloc();
    assert bid_theme_1[0] = 'Super theme';
    assert bid_theme_1[1] = 'is this theme';
    place_bid(
        auction_id=1,
        account=1212,
        amount=5000000000000000,
        timestamp=1667048632,
        theme_len=2,
        theme=bid_theme_1,
    );

    // Verify it worked
    let (bids_count) = IRtwrkThemeAuction.auctionBidsCount(auction_contract_address, 1);
    assert 1 = bids_count;

    // Verify the first bidder balance has decreased
    let (balance) = IERC20.balanceOf(eth_erc_20_contract_address, 1212);
    assert (100000000000000000000 - 5000000000000000) = balance.low;
    assert 0 = balance.high;

    // Get back the bid
    let (
        bidAccount: felt,
        bidAmount: Uint256,
        bidTimestamp: felt,
        bidReimbursementTimestamp: felt,
        theme_len: felt,
        theme: felt*,
    ) = IRtwrkThemeAuction.bid(auction_contract_address, 1, 1);

    assert 1212 = bidAccount;
    assert 5000000000000000 = bidAmount.low;
    assert 0 = bidAmount.high;
    assert 1667048632 = bidTimestamp;
    assert 2 = theme_len;
    assert 'Super theme' = theme[0];
    assert 'is this theme' = theme[1];

    // Place a second bid : second bidder needs some money first

    %{ store(context.eth_erc_20_contract_address, "ERC20_balances", [25000000000000000], key=[1313]) %}

    let (bid_theme_2: felt*) = alloc();
    assert bid_theme_2[0] = 'Second theme';

    place_bid(
        auction_id=1,
        account=1313,
        amount=15000000000000000,
        timestamp=1667048634,
        theme_len=1,
        theme=bid_theme_2,
    );

    // Verify it worked
    let (bids_count) = IRtwrkThemeAuction.auctionBidsCount(auction_contract_address, 1);
    assert 2 = bids_count;

    // Verify the second bidder balance has decreased
    let (balance) = IERC20.balanceOf(eth_erc_20_contract_address, 1313);
    assert 10000000000000000 = balance.low;
    assert 0 = balance.high;

    // Verify the first bidder balance has increased
    let (balance) = IERC20.balanceOf(eth_erc_20_contract_address, 1212);
    assert 100000000000000000000 = balance.low;
    assert 0 = balance.high;

    %{ expect_revert(error_message="Bid amount must be at least the last bid amount + BID_INCREMENT") %}

    // Trying a third bid but not enough money
    place_bid(
        auction_id=1,
        account=1313,
        amount=17000000000000000,
        timestamp=1667048636,
        theme_len=1,
        theme=bid_theme_2,
    );

    return ();
}

@view
func test_launch_rtwrk_too_soon{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}() {
    alloc_locals;
    local rtwrk_drawer_contract_address;
    %{ ids.rtwrk_drawer_contract_address = context.rtwrk_drawer_contract_address %}

    local auction_contract_address;
    %{ ids.auction_contract_address = context.auction_contract_address %}

    local eth_erc_20_contract_address;
    %{ ids.eth_erc_20_contract_address = context.eth_erc_20_contract_address %}

    launch_auction(1667048630);

    let (bid_theme_1: felt*) = alloc();
    assert bid_theme_1[0] = 'Super theme';
    assert bid_theme_1[1] = 'is this theme';
    place_bid(
        auction_id=1,
        account=1212,
        amount=5000000000000000,
        timestamp=1667048632,
        theme_len=2,
        theme=bid_theme_1,
    );

    // Now launch rtwrk
    %{ expect_revert(error_message="Cannot call this method while an auction is running") %}
    launch_rtwrk(1667048634);

    return ();
}

@view
func test_launch_rtwrk_no_bid{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}() {
    alloc_locals;
    local rtwrk_drawer_contract_address;
    %{ ids.rtwrk_drawer_contract_address = context.rtwrk_drawer_contract_address %}

    local auction_contract_address;
    %{ ids.auction_contract_address = context.auction_contract_address %}

    local eth_erc_20_contract_address;
    %{ ids.eth_erc_20_contract_address = context.eth_erc_20_contract_address %}

    launch_auction(1667048630);

    %{ expect_revert(error_message="Auction 1 has no bids") %}

    launch_rtwrk(1667048634 + 26 * 3600);

    return ();
}

@view
func test_launch_second_auction_if_no_bid{
    syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}() {
    alloc_locals;
    local rtwrk_drawer_contract_address;
    %{ ids.rtwrk_drawer_contract_address = context.rtwrk_drawer_contract_address %}

    local auction_contract_address;
    %{ ids.auction_contract_address = context.auction_contract_address %}

    local eth_erc_20_contract_address;
    %{ ids.eth_erc_20_contract_address = context.eth_erc_20_contract_address %}

    let (current_auction_id) = IRtwrkThemeAuction.currentAuctionId(auction_contract_address);
    assert 0 = current_auction_id;

    launch_auction(1667048630);

    let (current_auction_id) = IRtwrkThemeAuction.currentAuctionId(auction_contract_address);
    assert 1 = current_auction_id;

    launch_auction(1667048634 + 26 * 3600);

    let (current_auction_id) = IRtwrkThemeAuction.currentAuctionId(auction_contract_address);
    assert 2 = current_auction_id;

    return ();
}

@view
func test_launch_rtwrk{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}() {
    alloc_locals;
    local rtwrk_drawer_contract_address;
    %{ ids.rtwrk_drawer_contract_address = context.rtwrk_drawer_contract_address %}

    launch_auction(1667048630);

    let (bid_theme_1: felt*) = alloc();
    assert bid_theme_1[0] = 'Super theme';
    assert bid_theme_1[1] = 'is this theme';
    place_bid(
        auction_id=1,
        account=1212,
        amount=5000000000000000,
        timestamp=1667048632,
        theme_len=2,
        theme=bid_theme_1,
    );

    // Place a second bid : second bidder needs some money first

    %{ store(context.eth_erc_20_contract_address, "ERC20_balances", [25000000000000000], key=[1313]) %}

    let (bid_theme_2: felt*) = alloc();
    assert bid_theme_2[0] = 'Second theme';

    place_bid(
        auction_id=1,
        account=1313,
        amount=15000000000000000,
        timestamp=1667048634,
        theme_len=1,
        theme=bid_theme_2,
    );

    let (rtwrk_id) = IRtwrkDrawer.currentRtwrkId(contract_address=rtwrk_drawer_contract_address);
    assert ORIGINAL_RTWRKS_COUNT = rtwrk_id;

    // Now launch rtwrk
    launch_rtwrk(1667048634 + 26 * 3600);

    let (rtwrk_id) = IRtwrkDrawer.currentRtwrkId(contract_address=rtwrk_drawer_contract_address);
    assert ORIGINAL_RTWRKS_COUNT + 1 = rtwrk_id;

    // Second bid must have won!

    let (rtwrk_theme_len, rtwrk_theme: felt*) = IRtwrkDrawer.rtwrkTheme(
        rtwrk_drawer_contract_address, rtwrk_id
    );
    assert 1 = rtwrk_theme_len;
    assert 'Second theme' = rtwrk_theme[0];

    // Can't launch rtwrk a second time!

    %{ expect_revert(error_message="Rtwrk for auction 1 has already been launched at timestamp 1667142234") %}
    launch_rtwrk(1667048634 + 26 * 3600);

    return ();
}

@view
func test_settle_auction_too_soon{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}(
    ) {
    launch_auction(1667048630);

    let (bid_theme_1: felt*) = alloc();
    assert bid_theme_1[0] = 'Super theme';
    assert bid_theme_1[1] = 'is this theme';
    place_bid(
        auction_id=1,
        account=1212,
        amount=5000000000000000,
        timestamp=1667048632,
        theme_len=2,
        theme=bid_theme_1,
    );

    %{ expect_revert(error_message="Cannot call this method while an auction is running") %}

    settle_auction(1667048632 + 10);
    return ();
}

@view
func test_settle_auction_no_bids{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}(
    ) {
    launch_auction(1667048630);

    %{ expect_revert(error_message="Auction 1 has no bids") %}
    settle_auction(1667048630 + 27 * 3600);
    return ();
}

@view
func test_settle_auction_rtwrk_not_finished{
    syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}() {
    launch_auction(1667048630);

    let (bid_theme_1: felt*) = alloc();
    assert bid_theme_1[0] = 'Super theme';
    assert bid_theme_1[1] = 'is this theme';
    place_bid(
        auction_id=1,
        account=1212,
        amount=5000000000000000,
        timestamp=1667048632,
        theme_len=2,
        theme=bid_theme_1,
    );

    // Launch rtwrk
    launch_rtwrk(1667048634 + 26 * 3600);

    // Draw something in this rtwrk!
    colorize_pixels(1, 1667048634 + 26 * 3600 + 5);

    // Settle the auction
    %{ expect_revert(error_message="Cannot call this method while an rtwrk is running") %}
    settle_auction(1667048634 + 26 * 3600 + 24 * 3600);
    return ();
}

@view
func test_settle_auction{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}() {
    alloc_locals;

    local auction_contract_address;
    %{ ids.auction_contract_address = context.auction_contract_address %}

    local eth_erc_20_contract_address;
    %{ ids.eth_erc_20_contract_address = context.eth_erc_20_contract_address %}

    local rtwrk_erc721_contract_address;
    %{ ids.rtwrk_erc721_contract_address = context.rtwrk_erc721_contract_address %}

    launch_auction(1667048630);

    let (bid_theme_1: felt*) = alloc();
    assert bid_theme_1[0] = 'Super theme';
    assert bid_theme_1[1] = 'is this theme';
    // 5 ETH !
    place_bid(
        auction_id=1,
        account=1212,
        amount=5000000000000000000,
        timestamp=1667048632,
        theme_len=2,
        theme=bid_theme_1,
    );

    // Launch rtwrk
    launch_rtwrk(1667048634 + 26 * 3600);

    // Draw something in this rtwrk!
    colorize_pixels(6, 1667048634 + 26 * 3600 + 5);
    colorize_pixels(18, 1667048634 + 26 * 3600 + 5);
    colorize_pixels(356, 1667048634 + 26 * 3600 + 5);

    let (colorizer_balance) = IRtwrkThemeAuction.colorizerBalance(
        auction_contract_address, Uint256(6, 0)
    );
    assert 0 = colorizer_balance.low;
    assert 0 = colorizer_balance.high;

    let (pxls_balance) = IRtwrkThemeAuction.pxlsBalance(auction_contract_address);
    assert 0 = pxls_balance.low;
    assert 0 = pxls_balance.high;

    let (current_auction_id) = IRtwrkThemeAuction.currentAuctionId(auction_contract_address);
    assert 1 = current_auction_id;

    // Settle the auction
    settle_auction(1667048634 + 26 * 3600 + 26 * 3600);

    // Balances should have changed

    // There are 3 colorizers, sharing 90% of 5 eth = 4.5 ETH => 1.5 ETH each
    let (colorizer_auction_balance) = IRtwrkThemeAuction.colorizerBalance(
        auction_contract_address, Uint256(6, 0)
    );
    assert 1500000000000000000 = colorizer_auction_balance.low;
    assert 0 = colorizer_auction_balance.high;

    // PXLS new balance = 10% of 5 eth = 0.5 ETH
    let (pxls_auction_balance) = IRtwrkThemeAuction.pxlsBalance(auction_contract_address);
    assert 500000000000000000 = pxls_auction_balance.low;
    assert 0 = pxls_auction_balance.high;

    // A new auction should have been launched automatically

    let (current_auction_id) = IRtwrkThemeAuction.currentAuctionId(auction_contract_address);
    assert 2 = current_auction_id;

    // Withdrawal time!

    let (old_pxls_erc20_balance) = IERC20.balanceOf(eth_erc_20_contract_address, 123456);
    let (old_colorizer_erc20_balance) = IERC20.balanceOf(eth_erc_20_contract_address, 1414);

    IRtwrkThemeAuction.withdrawPxlsBalance(auction_contract_address);

    let (new_pxls_erc20_balance) = IERC20.balanceOf(eth_erc_20_contract_address, 123456);
    assert new_pxls_erc20_balance.low = old_pxls_erc20_balance.low + 500000000000000000;

    IRtwrkThemeAuction.withdrawColorizerBalance(auction_contract_address, Uint256(6, 0));
    let (new_colorizer_erc20_balance) = IERC20.balanceOf(eth_erc_20_contract_address, 1414);
    assert new_colorizer_erc20_balance.low = old_colorizer_erc20_balance.low + 1500000000000000000;

    // Auction balances went down after withdrawal
    let (colorizer_auction_balance) = IRtwrkThemeAuction.colorizerBalance(
        auction_contract_address, Uint256(6, 0)
    );
    assert 0 = colorizer_auction_balance.low;
    assert 0 = colorizer_auction_balance.high;

    // PXLS new balance = 10% of 5 eth = 0.5 ETH
    let (pxls_auction_balance) = IRtwrkThemeAuction.pxlsBalance(auction_contract_address);
    assert 0 = pxls_auction_balance.low;
    assert 0 = pxls_auction_balance.high;

    // The winner of the auction (1212) should have the new NFT!
    let (owner_address) = IRtwrkERC721.ownerOf(
        rtwrk_erc721_contract_address, Uint256(ORIGINAL_RTWRKS_COUNT + 1, 0)
    );
    assert 1212 = owner_address;

    // Now let's check if we can get the metadata of this NFT
    let (local token_uri_len, local token_uri: felt*) = IRtwrkERC721.tokenURI(
        rtwrk_erc721_contract_address, Uint256(ORIGINAL_RTWRKS_COUNT + 1, 0)
    );

    assert 'data:application/json;' = token_uri[0];
    let (rtwrk_id_literal) = literal_from_number(ORIGINAL_RTWRKS_COUNT + 1);
    assert rtwrk_id_literal = token_uri[2];
    assert '0\" fill=\"rgb(100,181,246' = token_uri[12];  // First pixel is colorized with color 28 = 100,181,246
    assert '</svg>' = token_uri[token_uri_len - 2];
    assert '"}' = token_uri[token_uri_len - 1];

    return ();
}

func launch_auction{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}(
    timestamp: felt
) {
    tempvar auction_contract_address;
    %{ ids.auction_contract_address = context.auction_contract_address %}

    // Fake time
    %{ warp(ids.timestamp, context.auction_contract_address) %}

    IRtwrkThemeAuction.launchAuction(auction_contract_address);
    return ();
}

func place_bid{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}(
    auction_id: felt, account: felt, amount: felt, timestamp: felt, theme_len: felt, theme: felt*
) {
    tempvar auction_contract_address;
    %{ ids.auction_contract_address = context.auction_contract_address %}

    tempvar eth_erc_20_contract_address;
    %{ ids.eth_erc_20_contract_address = context.eth_erc_20_contract_address %}

    %{ warp(ids.timestamp, context.auction_contract_address) %}

    %{ stop_prank_eth = start_prank(ids.account, target_contract_address=context.eth_erc_20_contract_address) %}

    // Before placing bid, let's allow spending of money
    IERC20.approve(
        contract_address=eth_erc_20_contract_address,
        spender=auction_contract_address,
        amount=Uint256(amount, 0),
    );

    %{ stop_prank_eth() %}

    %{ stop_prank_auction = start_prank(ids.account, target_contract_address=context.auction_contract_address) %}

    IRtwrkThemeAuction.placeBid(
        contract_address=auction_contract_address,
        auctionId=auction_id,
        bidAmount=Uint256(amount, 0),
        theme_len=theme_len,
        theme=theme,
    );

    %{ stop_prank_auction() %}
    return ();
}

func launch_rtwrk{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}(timestamp) {
    tempvar auction_contract_address;
    %{ ids.auction_contract_address = context.auction_contract_address %}

    %{ warp(ids.timestamp, context.auction_contract_address) %}
    %{ warp(ids.timestamp, context.rtwrk_drawer_contract_address) %}

    IRtwrkThemeAuction.launchAuctionRtwrk(auction_contract_address);
    return ();
}

func colorize_pixels{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}(
    pxl_id: felt, timestamp: felt
) {
    tempvar rtwrk_drawer_contract_address;
    %{ ids.rtwrk_drawer_contract_address = context.rtwrk_drawer_contract_address %}

    let (pixel_colorizations: PixelColorization*) = alloc();
    assert pixel_colorizations[0] = PixelColorization(pixel_index=0, color_index=28);
    assert pixel_colorizations[1] = PixelColorization(pixel_index=399, color_index=2);

    // To colorize we need to own a pxl
    %{ store(context.pxl_erc721_contract_address, "ERC721_balances", [1], key=[1414]) %}
    %{ store(context.pxl_erc721_contract_address, "ERC721_owners", [1414], key=[ids.pxl_id, 0]) %}

    %{ stop_prank_rtwrk_drawer = start_prank(1414, target_contract_address=context.rtwrk_drawer_contract_address) %}

    %{ warp(ids.timestamp, context.rtwrk_drawer_contract_address) %}

    IRtwrkDrawer.colorizePixels(
        rtwrk_drawer_contract_address, Uint256(pxl_id, 0), 2, pixel_colorizations
    );

    %{ stop_prank_rtwrk_drawer() %}
    return ();
}

func settle_auction{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}(
    timestamp: felt
) {
    tempvar auction_contract_address;
    %{ ids.auction_contract_address = context.auction_contract_address %}

    %{ warp(ids.timestamp, context.auction_contract_address) %}

    IRtwrkThemeAuction.settleAuction(auction_contract_address);
    return ();
}
