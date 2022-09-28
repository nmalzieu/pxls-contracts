%lang starknet
from starkware.cairo.common.uint256 import Uint256

struct Bid {
    account: felt,
    amount: Uint256,
    timestamp: felt,
    reimbursement_timestamp: felt,
    theme_len: felt,
    theme: felt*,
}
