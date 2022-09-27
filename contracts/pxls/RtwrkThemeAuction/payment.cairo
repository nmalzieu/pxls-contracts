%lang starknet
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256, assert_uint256_lt
from starkware.cairo.common.bool import TRUE

from openzeppelin.security.safemath.library import SafeUint256
from openzeppelin.security.reentrancyguard.library import ReentrancyGuard
from openzeppelin.access.ownable.library import Ownable

from pxls.RtwrkThemeAuction.bid_struct import Bid
from pxls.RtwrkThemeAuction.variables import PXLS_BID_AMOUNT_DIVISOR
from pxls.RtwrkThemeAuction.drawer import rtwrk_colorizers
from pxls.RtwrkThemeAuction.storage import colorizers_balance, pxls_balance, eth_erc20_address
from pxls.RtwrkThemeAuction.pxls_collection import get_current_owner_of_pxl

from pxls.interfaces import IRtwrkDrawer, IEthERC20

func settle_auction_payments{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    rtwrk_id: felt, bid: Bid
) {
    alloc_locals;
    ReentrancyGuard._start();
    let bid_amount = bid.amount;

    with_attr error_message("Trying to settle payments for a bid with amount 0") {
        assert_uint256_lt(Uint256(0, 0), bid_amount);
    }

    // Divide the total amount by PXLS_BID_AMOUNT_DIVISOR to get the pxls project part
    let (pxls_bid_amount, remainder) = SafeUint256.div_rem(
        bid_amount, Uint256(PXLS_BID_AMOUNT_DIVISOR, 0)
    );

    // The rest goes to the colorizers
    let (total_colorizers_bid_amount) = SafeUint256.sub_lt(bid_amount, pxls_bid_amount);

    // Let's get the list of drawers from this rtwrk
    let (colorizers_len, colorizers: felt*) = rtwrk_colorizers(rtwrk_id);

    // We need to divide the colorizers_bid_amount by the number of colorizers.

    let (each_colorizer_amount, remainder) = SafeUint256.div_rem(
        total_colorizers_bid_amount, Uint256(colorizers_len, 0)
    );

    // If there is a remainder, it goes to the pxls project so there is no preference
    let (pxls_bid_amount) = SafeUint256.add(pxls_bid_amount, remainder);

    // Increment balances with the money owed
    increment_pxls_balance(pxls_bid_amount);
    increment_colorizers_balances(each_colorizer_amount, colorizers_len, colorizers);

    ReentrancyGuard._end();
    return ();
}

func increment_pxls_balance{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    amount: Uint256
) {
    let (current_pxls_balance: Uint256) = pxls_balance.read();
    let (new_pxls_balance: Uint256) = SafeUint256.add(current_pxls_balance, amount);
    pxls_balance.write(new_pxls_balance);
    return ();
}

func increment_colorizer_balance{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    amount: Uint256, pxl_id: Uint256
) {
    let (current_colorizer_balance: Uint256) = colorizers_balance.read(pxl_id);
    let (new_colorizer_balance: Uint256) = SafeUint256.add(current_colorizer_balance, amount);
    colorizers_balance.write(pxl_id, new_colorizer_balance);
    return ();
}

func increment_colorizers_balances{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    amount: Uint256, colorizers_len, colorizers: felt*
) {
    if (colorizers_len == 0) {
        return ();
    }
    increment_colorizer_balance(amount, Uint256(colorizers[0], 0));
    return increment_colorizers_balances(amount, colorizers_len - 1, colorizers + 1);
}

func withdraw_pxls_balance{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    ReentrancyGuard._start();
    let (current_pxls_balance: Uint256) = pxls_balance.read();
    with_attr error_message("Trying to witdhraw but balance is 0") {
        assert_uint256_lt(Uint256(0, 0), current_pxls_balance);
    }
    pxls_balance.write(Uint256(0, 0));
    let (owner) = Ownable.owner();
    let (transfer_success) = transfer_eth(owner, current_pxls_balance);
    with_attr error_message("Could not transfer amount to pxls contract owner") {
        assert transfer_success = TRUE;
    }
    ReentrancyGuard._end();
    return ();
}

func withdraw_colorizer_balance{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    pxl_id: Uint256
) {
    ReentrancyGuard._start();
    let (current_colorizer_balance: Uint256) = colorizers_balance.read(pxl_id);
    with_attr error_message("Trying to witdhraw but balance is 0") {
        assert_uint256_lt(Uint256(0, 0), current_colorizer_balance);
    }
    colorizers_balance.write(pxl_id, Uint256(0, 0));
    // The person that receives the eth is the person that owns this pxl at the moment
    let (owner_of_pxl) = get_current_owner_of_pxl(pxl_id);
    let (transfer_success) = transfer_eth(owner_of_pxl, current_colorizer_balance);
    with_attr error_message("Could not transfer amount to colorizer") {
        assert transfer_success = TRUE;
    }
    ReentrancyGuard._end();
    return ();
}

func transfer_eth{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    recipient: felt, amount: Uint256
) -> (success: felt) {
    let (eth_contract_address) = eth_erc20_address.read();
    let (success) = IEthERC20.transfer(
        contract_address=eth_contract_address, recipient=recipient, amount=amount
    );
    return (success=success);
}

func transfer_eth_from{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    sender: felt, recipient: felt, amount: Uint256
) -> (success: felt) {
    let (eth_contract_address) = eth_erc20_address.read();
    let (success) = IEthERC20.transferFrom(
        contract_address=eth_contract_address, sender=sender, recipient=recipient, amount=amount
    );
    return (success=success);
}
