%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.uint256 import Uint256, assert_uint256_eq

from pxls.RtwrkThemeAuction.bid import (
    store_bid_theme,
    read_bid_theme,
    Bid,
    store_bid,
    read_bid,
    assert_bid_amount_valid,
    assert_bid_theme_valid_and_pack,
    place_bid,
)
from pxls.RtwrkThemeAuction.storage import (
    auction_bids_count,
    current_auction_id,
    auction_timestamp,
    eth_erc20_address,
    bid_reimbursement_timestamp,
    bid_increment,
)

@view
func test_store_bid_theme{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}() {
    let (theme: felt*) = alloc();
    assert theme[0] = 'My super theme';
    assert theme[1] = 'is many felts';
    assert theme[2] = 'exactly 2';
    store_bid_theme(auction_id=12, bid_id=1, theme_index=0, theme_len=3, theme=theme);

    let (stored_theme_len: felt, stored_theme: felt*) = read_bid_theme(12, 1);
    assert 3 = stored_theme_len;
    assert 'My super theme' = stored_theme[0];
    assert 'is many felts' = stored_theme[1];
    assert 'exactly 2' = stored_theme[2];

    return ();
}

@view
func test_store_bid{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}() {
    alloc_locals;
    let (bids_count) = auction_bids_count.read(2);

    assert 0 = bids_count;

    let (theme: felt*) = alloc();
    assert theme[0] = 'My super theme';
    assert theme[1] = 'is many felts';
    assert theme[2] = 'exactly 2';

    let bid = Bid(
        account='account',
        amount=Uint256(12, 0),
        timestamp=1664192254,
        reimbursement_timestamp=12,
        theme_len=3,
        theme=theme,
    );
    store_bid(auction_id=2, bid=bid);

    let (bids_count) = auction_bids_count.read(2);
    assert 1 = bids_count;

    let (stored_bid) = read_bid(auction_id=2, bid_id=1);

    assert_uint256_eq(Uint256(12, 0), stored_bid.amount);
    assert 'account' = stored_bid.account;
    assert 3 = stored_bid.theme_len;
    assert 'My super theme' = stored_bid.theme[0];
    assert 'is many felts' = stored_bid.theme[1];
    assert 'exactly 2' = stored_bid.theme[2];
    assert 1664192254 = stored_bid.timestamp;
    assert 0 = stored_bid.reimbursement_timestamp;  // This is not updated via store_bid

    let (unexistent_stored_bid) = read_bid(auction_id=2, bid_id=2);

    assert_uint256_eq(Uint256(0, 0), unexistent_stored_bid.amount);
    assert 0 = unexistent_stored_bid.account;
    assert 0 = unexistent_stored_bid.theme_len;
    assert 0 = unexistent_stored_bid.timestamp;

    return ();
}

@view
func test_validate_bid_theme_too_long{
    syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}() {
    let (theme_len, theme) = get_unpacked_theme_too_long();

    %{ expect_revert(error_message="Theme is too long") %}
    assert_bid_theme_valid_and_pack(theme_len, theme);

    return ();
}

@view
func test_validate_first_bid_amount_too_low{
    syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}() {
    alloc_locals;
    bid_increment.write(5000000000000000);
    let (theme: felt*) = alloc();
    assert theme[0] = 'My super theme';

    let bid = Bid(
        account='account',
        amount=Uint256(2000000000000000, 0),
        timestamp=1664192254,
        reimbursement_timestamp=0,
        theme_len=1,
        theme=theme,
    );

    %{ expect_revert(error_message="Bid amount must be at least bid_increment since last bid is 0") %}
    assert_bid_amount_valid(auction_id=2, bid=bid);

    return ();
}

@view
func test_validate_second_bid_amount_too_low{
    syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}() {
    alloc_locals;
    bid_increment.write(5000000000000000);
    let (theme_len, theme) = get_unpacked_theme();

    let bid = Bid(
        account='account',
        amount=Uint256(7000000000000000, 0),
        timestamp=1664192254,
        reimbursement_timestamp=0,
        theme_len=theme_len,
        theme=theme,
    );

    assert_bid_amount_valid(auction_id=2, bid=bid);
    store_bid(auction_id=2, bid=bid);

    let bid = Bid(
        account='account',
        amount=Uint256(0, 0),
        timestamp=1664192254,
        reimbursement_timestamp=0,
        theme_len=theme_len,
        theme=theme,
    );

    %{ expect_revert(error_message="Bid amount must be at least the last bid amount + bid_increment") %}
    assert_bid_amount_valid(auction_id=2, bid=bid);

    return ();
}

@view
func test_place_bid{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}() {
    alloc_locals;

    %{ warp(1664192254) %}
    %{ stop_prank = start_prank(121212) %}

    current_auction_id.write(12);
    auction_timestamp.write(12, 1664192254);
    let eth_erc20_address_value = 'eth_erc20_address';
    eth_erc20_address.write(eth_erc20_address_value);

    let (count) = auction_bids_count.read(12);
    assert 0 = count;

    let (local theme_len, local theme) = get_unpacked_theme();

    // Mocking the erc20 transferFrom
    %{ stop_mock_erc20 = mock_call(ids.eth_erc20_address_value, "transferFrom", [1]) %}

    place_bid(
        auction_id=12, bid_amount=Uint256(5000000000000000, 0), theme_len=theme_len, theme=theme
    );

    // Verify that new bid was saved

    let (count) = auction_bids_count.read(12);
    assert 1 = count;

    // Verify data from the new bid
    let (stored_bid) = read_bid(auction_id=12, bid_id=1);
    assert_uint256_eq(Uint256(5000000000000000, 0), stored_bid.amount);
    assert 121212 = stored_bid.account;
    assert 1664192254 = stored_bid.timestamp;
    assert 2 = stored_bid.theme_len;
    assert 'My+super+theme+is+many+felts+ex' = stored_bid.theme[0];
    assert 'actly+2' = stored_bid.theme[1];

    // New bid is not reimbursed

    let (timestamp) = bid_reimbursement_timestamp.read(12, 0);
    assert 0 = timestamp;

    // Mocking the erc20 transferFrom
    %{ stop_mock_erc20 = mock_call(ids.eth_erc20_address_value, "transfer", [1]) %}

    // Place another bid

    place_bid(auction_id=12, bid_amount=Uint256(12000000000000000, 0), theme_len=theme_len, theme=theme);

    // Verify that it was saved

    let (count) = auction_bids_count.read(12);
    assert 2 = count;

    // Verify that first one was reimbursed
    let (stored_bid) = read_bid(auction_id=12, bid_id=1);
    assert 1664192254 = stored_bid.reimbursement_timestamp;

    // Verify that new one not reimbursed
    let (stored_bid) = read_bid(auction_id=12, bid_id=2);
    assert 0 = stored_bid.reimbursement_timestamp;

    %{
        expect_events(
            {
               "name": "bid_placed",
               "data": {
                   "auction_id": 12,
                   "caller_account_address": 121212,
                   "amount": 5000000000000000,
                   "theme": [136883506732829103107092713290711344076018938498406411881685150130246477176, 27412424428170034]
               }
           },
           {
               "name": "bid_placed",
               "data": {
                   "auction_id": 12,
                   "caller_account_address": 121212,
                   "amount": 12000000000000000,
                   "theme": [136883506732829103107092713290711344076018938498406411881685150130246477176, 27412424428170034]
               }
           }
        )
    %}

    return ();
}

func get_unpacked_theme{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}() -> (
    theme_len: felt, theme: felt*
) {
    let (theme: felt*) = alloc();
    assert theme[0] = 'M';
    assert theme[1] = 'y';
    assert theme[2] = '+';
    assert theme[3] = 's';
    assert theme[4] = 'u';
    assert theme[5] = 'p';
    assert theme[6] = 'e';
    assert theme[7] = 'r';
    assert theme[8] = '+';
    assert theme[9] = 't';
    assert theme[10] = 'h';
    assert theme[11] = 'e';
    assert theme[12] = 'm';
    assert theme[13] = 'e';
    assert theme[14] = '+';
    assert theme[15] = 'i';
    assert theme[16] = 's';
    assert theme[17] = '+';
    assert theme[18] = 'm';
    assert theme[19] = 'a';
    assert theme[20] = 'n';
    assert theme[21] = 'y';
    assert theme[22] = '+';
    assert theme[23] = 'f';
    assert theme[24] = 'e';
    assert theme[25] = 'l';
    assert theme[26] = 't';
    assert theme[27] = 's';
    assert theme[28] = '+';
    assert theme[29] = 'e';
    assert theme[30] = 'x';
    assert theme[31] = 'a';
    assert theme[32] = 'c';
    assert theme[33] = 't';
    assert theme[34] = 'l';
    assert theme[35] = 'y';
    assert theme[36] = '+';
    assert theme[37] = '2';

    return (38, theme);
}

func get_unpacked_theme_too_long{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}(
    ) -> (theme_len: felt, theme: felt*) {
    let (theme: felt*) = alloc();
    assert theme[0] = 'a';
    assert theme[1] = 'a';
    assert theme[2] = 'a';
    assert theme[3] = 'a';
    assert theme[4] = 'a';
    assert theme[5] = 'a';
    assert theme[6] = 'a';
    assert theme[7] = 'a';
    assert theme[8] = 'a';
    assert theme[9] = 'a';
    assert theme[10] = 'a';
    assert theme[11] = 'a';
    assert theme[12] = 'a';
    assert theme[13] = 'a';
    assert theme[14] = 'a';
    assert theme[15] = 'a';
    assert theme[16] = 'a';
    assert theme[17] = 'a';
    assert theme[18] = 'a';
    assert theme[19] = 'a';
    assert theme[20] = 'a';
    assert theme[21] = 'a';
    assert theme[22] = 'a';
    assert theme[23] = 'a';
    assert theme[24] = 'a';
    assert theme[25] = 'a';
    assert theme[26] = 'a';
    assert theme[27] = 'a';
    assert theme[28] = 'a';
    assert theme[29] = 'a';
    assert theme[30] = 'a';
    assert theme[31] = 'a';
    assert theme[32] = 'a';
    assert theme[33] = 'a';
    assert theme[34] = 'a';
    assert theme[35] = 'a';
    assert theme[36] = 'a';
    assert theme[37] = 'a';
    assert theme[38] = 'a';
    assert theme[39] = 'a';
    assert theme[40] = 'a';
    assert theme[41] = 'a';
    assert theme[42] = 'a';
    assert theme[43] = 'a';
    assert theme[44] = 'a';
    assert theme[45] = 'a';
    assert theme[46] = 'a';
    assert theme[47] = 'a';
    assert theme[48] = 'a';
    assert theme[49] = 'a';
    assert theme[50] = 'a';
    assert theme[51] = 'a';
    assert theme[52] = 'a';
    assert theme[53] = 'a';
    assert theme[54] = 'a';
    assert theme[55] = 'a';
    assert theme[56] = 'a';
    assert theme[57] = 'a';
    assert theme[58] = 'a';
    assert theme[59] = 'a';
    assert theme[60] = 'a';
    assert theme[61] = 'a';
    assert theme[62] = 'a';
    assert theme[63] = 'a';
    assert theme[64] = 'a';
    assert theme[65] = 'a';
    assert theme[66] = 'a';
    assert theme[67] = 'a';
    assert theme[68] = 'a';
    assert theme[69] = 'a';
    assert theme[70] = 'a';
    assert theme[71] = 'a';
    assert theme[72] = 'a';
    assert theme[73] = 'a';
    assert theme[74] = 'a';
    assert theme[75] = 'a';
    assert theme[76] = 'a';
    assert theme[77] = 'a';
    assert theme[78] = 'a';
    assert theme[79] = 'a';
    assert theme[80] = 'a';
    assert theme[81] = 'a';
    assert theme[82] = 'a';
    assert theme[83] = 'a';
    assert theme[84] = 'a';
    assert theme[85] = 'a';
    assert theme[86] = 'a';
    assert theme[87] = 'a';
    assert theme[88] = 'a';
    assert theme[89] = 'a';
    assert theme[90] = 'a';
    assert theme[91] = 'a';
    assert theme[92] = 'a';
    assert theme[93] = 'a';
    assert theme[94] = 'a';
    assert theme[95] = 'a';
    assert theme[96] = 'a';
    assert theme[97] = 'a';
    assert theme[98] = 'a';
    assert theme[99] = 'a';
    assert theme[100] = 'a';
    assert theme[101] = 'a';
    assert theme[102] = 'a';
    assert theme[103] = 'a';
    assert theme[104] = 'a';
    assert theme[105] = 'a';
    assert theme[106] = 'a';
    assert theme[107] = 'a';
    assert theme[108] = 'a';
    assert theme[109] = 'a';
    assert theme[110] = 'a';
    assert theme[111] = 'a';
    assert theme[112] = 'a';
    assert theme[113] = 'a';
    assert theme[114] = 'a';
    assert theme[115] = 'a';
    assert theme[116] = 'a';
    assert theme[117] = 'a';
    assert theme[118] = 'a';
    assert theme[119] = 'a';
    assert theme[120] = 'a';
    assert theme[121] = 'a';
    assert theme[122] = 'a';
    assert theme[123] = 'a';
    assert theme[124] = 'a';
    assert theme[125] = 'a';
    assert theme[126] = 'a';
    assert theme[127] = 'a';
    assert theme[128] = 'a';
    assert theme[129] = 'a';
    assert theme[130] = 'a';
    assert theme[131] = 'a';
    assert theme[132] = 'a';
    assert theme[133] = 'a';
    assert theme[134] = 'a';
    assert theme[135] = 'a';
    assert theme[136] = 'a';
    assert theme[137] = 'a';
    assert theme[138] = 'a';
    assert theme[139] = 'a';
    assert theme[140] = 'a';
    assert theme[141] = 'a';
    assert theme[142] = 'a';
    assert theme[143] = 'a';
    assert theme[144] = 'a';
    assert theme[145] = 'a';
    assert theme[146] = 'a';
    assert theme[147] = 'a';
    assert theme[148] = 'a';
    assert theme[149] = 'a';
    assert theme[150] = 'a';
    assert theme[151] = 'a';
    assert theme[152] = 'a';
    assert theme[153] = 'a';
    assert theme[154] = 'a';
    assert theme[155] = 'a';
    assert theme[156] = 'a';

    return (157, theme);
}
