use starknet::ContractAddress;
use starknet::class_hash::ClassHash;
use pxls_contracts::rtwrk::rtwrk_erc721::RtwrkERC721Trait;
use starknet::{get_caller_address, storage};
use openzeppelin::token::erc721::ERC721Component;
use openzeppelin::access::ownable::Ownable;

#[starknet::interface]
trait RtwrkERC721Trait<TContractState> {
    fn supports_interface(self: @TContractState) -> felt252;
    fn name(self: @TContractState) -> felt252;
    fn symbol(self: @TContractState) -> felt252;
    fn balance_of(self: @TContractState, owner: felt252) -> u256;
    fn owner_of(self: @TContractState, token_id: u256) -> felt252;
    fn exists(self: @TContractState, token_id: u256) -> bool;
    fn get_approved(self: @TContractState, token_id: u256) -> felt252;
    fn is_approved_for_all(self: @TContractState, owner: felt252, operator: felt252) -> bool;
    fn contract_uri(self: @TContractState) -> felt252;
    fn token_uri(self: @TContractState, token_id: u256) -> felt252;
    fn owner(self: @TContractState) -> felt252;
    fn total_supply(self: @TContractState) -> u256;
    fn rtwrk_step(self: @TContractState, token_id: u256) -> felt252;
}

#[starknet::contract]
mod RtwrkERC721 {
    use super::*;

    #[storage]
    struct Storage {
        name: felt252,
        symbol: felt252,
        rtwrk_drawer_address: ContractAddress,
        rtwrk_theme_auction_address: ContractAddress,
        contract_uri_hash: LegacyMap<u256, felt252>,
        rtwrk_chosen_step: LegacyMap<u256, felt252>,
    }

    #[constructor]
    fn constructor(
        ref self: ContractState,
        proxy_admin: ContractAddress,
        owner: felt252,
        rtwrk_drawer_address_value: ContractAddress,
       
    ) {
      
    }

    #[external(v0)]
    impl RtwrkERC721Impl of super::RtwrkERC721Trait<ContractState> {
     
    }

    #[external(v0)]
    fn mint(
        ref self: ContractState,
        to: felt252,
        token_id: u256
    ) {
    }
}

