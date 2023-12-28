use starknet::ContractAddress;
use starknet::class_hash::ClassHash;
use pxls_contracts::upgradeable::upgradeable::Upgradeable;

#[starknet::interface]
trait PxlERC721Trait<TContractState> {
    fn get_minted_count(self: @TContractState) -> u256;
    fn total_supply(self: @TContractState) -> u256;
    fn contract_uri_hash(self: @TContractState) -> felt252;
    fn matrix_size(self: @TContractState) -> u256;
    fn max_supply(self: @TContractState) -> u256;
    fn pxls_owned(self: @TContractState, owner: felt252) -> u256;
    fn upgrade(ref self: TContractState, impl_hash: ClassHash);
}

#[starknet::contract]
mod PxlERC721 {
    use super::{
        ClassHash, Upgradeable };
    use pxls_contracts::pxls::pxls_erc721::pxls_erc721::PxlERC721Trait;
    use starknet::{ContractAddress, get_caller_address};
    use openzeppelin::introspection::src5::SRC5Component;
    use openzeppelin::token::erc721::ERC721Component;
    use pxls_contracts::admin::admin::Ownable;

    component!(path: SRC5Component, storage: src5, event: SRC5Event);
    component!(path: ERC721Component, storage: erc721, event: ERC721Event);


    #[abi(embed_v0)]
    impl SRC5Impl = SRC5Component::SRC5Impl<ContractState>;

    // ERC721
    #[abi(embed_v0)]
    impl ERC721Impl = ERC721Component::ERC721Impl<ContractState>;
    #[abi(embed_v0)]
    impl ERC721MetadataImpl = ERC721Component::ERC721MetadataImpl<ContractState>;
    #[abi(embed_v0)]
    impl ERC721CamelOnly = ERC721Component::ERC721CamelOnlyImpl<ContractState>;
    #[abi(embed_v0)]
    impl ERC721MetadataCamelOnly =
        ERC721Component::ERC721MetadataCamelOnlyImpl<ContractState>;
    impl ERC721InternalImpl = ERC721Component::InternalImpl<ContractState>;


    #[storage]
    struct Storage {
        #[substorage(v0)]
        erc721: ERC721Component::Storage,
        #[substorage(v0)]
        src5: SRC5Component::Storage,
        minted_count: u256,
        matrix_size: u256,
        contract_uri_hash: LegacyMap::<u256, felt252>,
        pxls_1_100: ContractAddress,
        pxls_101_200: ContractAddress,
        pxls_201_300: ContractAddress,
        pxls_301_400: ContractAddress,
        original_pixel_erc721: ContractAddress
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        ERC721Event: ERC721Component::Event,
        #[flat]
        SRC5Event: SRC5Component::Event
    }

    #[constructor]
    fn constructor(
        ref self: ContractState,
        proxy_admin: ContractAddress,
        name: felt252,
        symbol: felt252,
        m_size: u256,
        owner: felt252,
        pxls_1_100_address: ContractAddress,
        pxls_101_200_address: ContractAddress,
        pxls_201_300_address: ContractAddress,
        pxls_301_400_address: ContractAddress,
        original_pixel_erc721_address: ContractAddress
    ) {
        //Proxy::initializer(proxy_admin);
        self.erc721.initializer(name, symbol);
        let mut state: Ownable::ContractState = Ownable::unsafe_new_contract_state();
        Ownable::InternalImpl::initializer(ref state, proxy_admin);

        self.matrix_size.write(m_size);
        self.pxls_1_100.write(pxls_1_100_address);
        self.pxls_101_200.write(pxls_101_200_address);
        self.pxls_201_300.write(pxls_201_300_address);
        self.pxls_301_400.write(pxls_301_400_address);
        self.original_pixel_erc721.write(original_pixel_erc721_address);
    }

    #[external(v0)]
    impl PxlERC721Impl of super::PxlERC721Trait<ContractState> {

        fn upgrade(ref self: ContractState, impl_hash: ClassHash){
            PxlERC721Internal::assert_only_admin();
            let mut upstate: Upgradeable::ContractState = Upgradeable::unsafe_new_contract_state();
            Upgradeable::InternalImpl::upgrade(ref upstate, impl_hash);
        }

        fn contract_uri_hash(self: @ContractState) -> felt252 {
            return 0;
        }

        fn matrix_size(self: @ContractState) -> u256 {
            return self.matrix_size.read();
        }

        fn max_supply(self: @ContractState) -> u256 {
            return 0;
        }

        fn pxls_owned(self: @ContractState, owner: felt252) -> u256 {
            return 0;
        }

        fn get_minted_count(self: @ContractState) -> u256 {
            return self.minted_count.read();
        }

        fn total_supply(self: @ContractState) -> u256 {
            return self.minted_count.read();
        }
    }

    #[generate_trait]
    impl PxlERC721Internal of IPxlERC721InternalTrait {

        fn assert_only_admin() {
            let state: Ownable::ContractState = Ownable::unsafe_new_contract_state();
            let admin = Ownable::OwnableImpl::owner(@state);
            let caller = get_caller_address(); 
            assert(admin == caller,'Admin: unauthorized');
        }
        
    }
}