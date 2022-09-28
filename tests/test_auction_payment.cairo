%lang starknet
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.uint256 import Uint256, assert_uint256_eq

from openzeppelin.access.ownable.library import Ownable

from pxls.RtwrkThemeAuction.storage import (
    colorizers_balance,
    pxls_balance,
    rtwrk_drawer_address,
    eth_erc20_address,
    pxls_erc721_address,
)
from pxls.RtwrkThemeAuction.bid_struct import Bid
from pxls.RtwrkThemeAuction.payment import (
    settle_auction_payments,
    withdraw_colorizer_balance,
    withdraw_pxls_balance,
)

@view
func test_settle_auction_payment_5_eth{
    syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}() {
    alloc_locals;
    assert_pxls_balance(0);
    assert_colorizer_balance(6, 0);
    assert_colorizer_balance(18, 0);
    assert_colorizer_balance(356, 0);

    let rtwrk_contract_address = 'rtwrk_contract_address';
    rtwrk_drawer_address.write(rtwrk_contract_address);

    %{ stop_mock_colorizers = mock_call(ids.rtwrk_contract_address, "colorizers", [3, 6, 18, 356]) %}

    let bid = get_sample_bid(5000000000000000000);  // 5 ETH
    settle_auction_payments(rtwrk_id=1, bid=bid);

    // PXLS new balance = 10% of 5 eth = 0.5 ETH
    assert_pxls_balance(500000000000000000);

    // There are 3 colorizers, sharing 90% of 5 eth = 4.5 ETH => 1.5 ETH each
    assert_colorizer_balance(6, 1500000000000000000);
    assert_colorizer_balance(18, 1500000000000000000);
    assert_colorizer_balance(356, 1500000000000000000);
    assert_colorizer_balance(357, 0);

    return ();
}

@view
func test_settle_auction_payment_0_9_eth{
    syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}() {
    alloc_locals;

    let rtwrk_contract_address = 'rtwrk_contract_address';
    rtwrk_drawer_address.write(rtwrk_contract_address);

    %{ stop_mock_colorizers = mock_call(ids.rtwrk_contract_address, "colorizers", [3, 6, 18, 356]) %}

    let bid = get_sample_bid(900000000000000000);  // 0.9 ETH
    settle_auction_payments(rtwrk_id=1, bid=bid);

    // PXLS new balance = 10% of 0.9 eth = 0.09 ETH
    assert_pxls_balance(90000000000000000);

    // There are 3 colorizers, sharing rest = 0.81 ETH => 0.27 ETH each
    assert_colorizer_balance(6, 270000000000000000);
    assert_colorizer_balance(18, 270000000000000000);
    assert_colorizer_balance(356, 270000000000000000);

    return ();
}

@view
func test_settle_auction_payment_1_1_eth{
    syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}() {
    alloc_locals;

    let rtwrk_contract_address = 'rtwrk_contract_address';
    rtwrk_drawer_address.write(rtwrk_contract_address);

    %{ stop_mock_colorizers = mock_call(ids.rtwrk_contract_address, "colorizers", [7, 6, 18, 356, 213, 4, 87, 132]) %}

    let bid = get_sample_bid(1100000000000000000);  // 1.1 ETH
    settle_auction_payments(rtwrk_id=1, bid=bid);

    // PXLS new balance = 10% of 1100000000000000000 wei = 110000000000000000 wei

    // There are 7 colorizers, sharing rest = 990000000000000000, divrem has a remainder
    // We have 990000000000000000 = 141428571428571428 × 7 + 4 => the remainder 4 goes to pxls
    assert_colorizer_balance(6, 141428571428571428);
    assert_colorizer_balance(18, 141428571428571428);
    assert_colorizer_balance(356, 141428571428571428);
    assert_colorizer_balance(213, 141428571428571428);
    assert_colorizer_balance(4, 141428571428571428);
    assert_colorizer_balance(87, 141428571428571428);
    assert_colorizer_balance(132, 141428571428571428);

    // Real pxls balance is 110000000000000000 (10%) + 4 wei (remainder)
    assert_pxls_balance(110000000000000004);

    return ();
}

@view
func test_settle_auction_payment_wei{
    syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}() {
    alloc_locals;

    let rtwrk_contract_address = 'rtwrk_contract_address';
    rtwrk_drawer_address.write(rtwrk_contract_address);

    %{ stop_mock_colorizers = mock_call(ids.rtwrk_contract_address, "colorizers", [2, 6, 18]) %}

    let bid = get_sample_bid(12);  // 12 wei
    settle_auction_payments(rtwrk_id=1, bid=bid);

    // PXLS new balance = 10% of 12 wei = 1.2 wei = 1 wei
    // Colorizers balance = 12 - 1 = 11 wei
    // Share 11 wei between 2 colorizers ? 5 wei each, remains 1 wei for pxls

    assert_colorizer_balance(6, 5);
    assert_colorizer_balance(18, 5);

    assert_pxls_balance(2);

    return ();
}

@view
func test_settle_auction_payment_400_colorizers{
    syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}() {
    alloc_locals;

    let rtwrk_contract_address = 'rtwrk_contract_address';
    rtwrk_drawer_address.write(rtwrk_contract_address);

    %{ stop_mock_colorizers = mock_call(ids.rtwrk_contract_address, "colorizers", [400] + list(range(1, 401))) %}

    let bid = get_sample_bid(5000000000000200);  // wei
    settle_auction_payments(rtwrk_id=1, bid=bid);

    // PXLS new balance = 10% of 5000000000000200 wei = 500000000000020 wei
    // Colorizers balance = 5000000000000200 - 500000000000020 = 4500000000000180
    // Share 4500000000000180 wei between 400 colorizers ? 11250000000000,45 wei each => 11250000000000 wei each
    // Rest = 4500000000000180 - 400 * 11250000000000 = 180 wei more for pxls

    assert_colorizer_balance(6, 11250000000000);
    assert_colorizer_balance(400, 11250000000000);

    assert_pxls_balance(500000000000020 + 180);

    return ();
}

@view
func test_withdraw_pxls_no_balance{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}(
    ) {
    %{ expect_revert(error_message="Trying to witdhraw but balance is 0") %}
    withdraw_pxls_balance();

    return ();
}

@view
func test_withdraw_transfer_fail{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}(
    ) {
    alloc_locals;

    let rtwrk_contract_address = 'rtwrk_contract_address';
    rtwrk_drawer_address.write(rtwrk_contract_address);

    %{ stop_mock_colorizers = mock_call(ids.rtwrk_contract_address, "colorizers", [3, 6, 18, 356]) %}

    let bid = get_sample_bid(900000000000000000);  // 0.9 ETH
    settle_auction_payments(rtwrk_id=1, bid=bid);

    // PXLS new balance = 0.09 ETH
    // Each colorizer balance = 0.27 ETH

    let eth_erc20_address_value = 'eth_erc20_address';
    eth_erc20_address.write(eth_erc20_address_value);

    // Returning 0 means the transfer didn't work
    %{ stop_mock_erc20 = mock_call(ids.eth_erc20_address_value, "transfer", [0]) %}

    %{ expect_revert(error_message="Could not transfer amount to pxls contract owner") %}
    withdraw_pxls_balance();

    return ();
}

@view
func test_withdraw_transfer{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}() {
    alloc_locals;

    %{ start_prank(121212) %}
    Ownable.initializer(121213);

    let rtwrk_contract_address = 'rtwrk_contract_address';
    rtwrk_drawer_address.write(rtwrk_contract_address);

    %{ stop_mock_colorizers = mock_call(ids.rtwrk_contract_address, "colorizers", [3, 6, 18, 356]) %}

    let bid = get_sample_bid(900000000000000000);  // 0.9 ETH
    settle_auction_payments(rtwrk_id=1, bid=bid);

    // PXLS new balance = 0.09 ETH
    assert_pxls_balance(90000000000000000);
    // Each colorizer balance = 0.27 ETH
    assert_colorizer_balance(6, 270000000000000000);
    assert_colorizer_balance(18, 270000000000000000);
    assert_colorizer_balance(356, 270000000000000000);

    let eth_erc20_address_value = 'eth_erc20_address';
    eth_erc20_address.write(eth_erc20_address_value);

    // Returning 1 means the transfer worked
    %{ stop_mock_erc20 = mock_call(ids.eth_erc20_address_value, "transfer", [1]) %}

    // Balances must drop to 0 when we withdraw

    withdraw_pxls_balance();
    assert_pxls_balance(0);

    // Mocking the value of the owner of the pxl id 6
    let pxls_collection_address_value = 'pxls_collection_address';
    pxls_erc721_address.write(pxls_collection_address_value);
    %{ stop_mock_pxls_collection = mock_call(ids.pxls_collection_address_value, "ownerOf", [123456]) %}

    withdraw_colorizer_balance(Uint256(18, 0));
    assert_colorizer_balance(6, 270000000000000000);
    assert_colorizer_balance(18, 0);
    assert_colorizer_balance(356, 270000000000000000);

    %{
        expect_events(
            {
               "name": "pxls_balance_withdrawn",
               "data": {
                   "caller_account_address": 121212,
                   "amount": 90000000000000000,
                   "recipient": 121213,
               }
           },
           {
               "name": "colorizer_balance_withdrawn",
               "data": {
                   "caller_account_address": 121212,
                   "amount": 270000000000000000,
                   "pxl_id": 18,
                   "recipient": 123456
               }
           }
        )
    %}

    return ();
}

func assert_pxls_balance{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}(
    balance: felt
) {
    alloc_locals;
    let (current_pxls_balance) = pxls_balance.read();
    assert balance = current_pxls_balance.low;
    assert 0 = current_pxls_balance.high;
    return ();
}

func assert_colorizer_balance{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}(
    pxl_id: felt, balance: felt
) {
    alloc_locals;
    let (current_colorizer_balance) = colorizers_balance.read(Uint256(pxl_id, 0));
    assert balance = current_colorizer_balance.low;
    assert 0 = current_colorizer_balance.high;
    return ();
}

func get_sample_bid{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}(
    bid_amount: felt
) -> Bid {
    let (theme: felt*) = alloc();
    assert theme[0] = 'My super theme';
    let bid = Bid(
        account=12,
        amount=Uint256(bid_amount, 0),
        timestamp=1664192254,
        reimbursement_timestamp=0,
        theme_len=1,
        theme=theme,
    );
    return bid;
}
