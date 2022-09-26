%lang starknet

struct Bid {
    account: felt,
    amount: felt,
    theme_len: felt,
    theme: felt*,
}
