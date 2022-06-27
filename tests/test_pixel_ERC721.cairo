%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256

@contract_interface
namespace IPixelERC721:
    func pixelDrawerAddress() -> (address : felt):
    end
    func initialize(pixel_drawer_address : felt):
    end
    func matrixSize() -> (size : Uint256):
    end
    func maxSupply() -> (count : Uint256):
    end
    func totalSupply() -> (count : Uint256):
    end
    func mint(to : felt):
    end
end

@view
func __setup__{syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*}():
    let name = 'Pixel'
    let symbol = 'PXL'
    let account = 123456
    %{ context.pixel_contract_address = deploy_contract("contracts/PixelERC721.cairo", [ids.name, ids.symbol, ids.account, 2, 0]).contract_address %}
    return ()
end

@view
func test_pixel_erc721_initializable{
    syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*
}():
    tempvar pixel_contract_address
    %{ ids.pixel_contract_address = context.pixel_contract_address %}

    # Drawer address must be 0

    let (pixel_drawer_address) = IPixelERC721.pixelDrawerAddress(
        contract_address=pixel_contract_address
    )
    assert pixel_drawer_address = 0

    # Set drawer address

    %{ stop_prank = start_prank(123456, target_contract_address=ids.pixel_contract_address) %}

    IPixelERC721.initialize(
        contract_address=pixel_contract_address, pixel_drawer_address='pixel_drawer_address'
    )

    # Drawer address must have been set

    let (pixel_drawer_address) = IPixelERC721.pixelDrawerAddress(
        contract_address=pixel_contract_address
    )
    assert pixel_drawer_address = 'pixel_drawer_address'

    # Drawer address cannot be set again

    %{ expect_revert(error_message="Pixel contract already initialized") %}
    IPixelERC721.initialize(
        contract_address=pixel_contract_address, pixel_drawer_address='pixel_drawer_address'
    )

    %{ stop_prank() %}
    return ()
end

@view
func test_pixel_erc721_getters{syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*}():
    tempvar pixel_contract_address
    %{ ids.pixel_contract_address = context.pixel_contract_address %}

    let (matrix_size : Uint256) = IPixelERC721.matrixSize(contract_address=pixel_contract_address)
    assert matrix_size.low = 2
    assert matrix_size.high = 0

    let (max_supply : Uint256) = IPixelERC721.maxSupply(contract_address=pixel_contract_address)
    assert max_supply.low = 4
    assert max_supply.high = 0

    # Check that minted pixels count is 0

    let (total_supply : Uint256) = IPixelERC721.totalSupply(contract_address=pixel_contract_address)
    assert total_supply.low = 0
    assert total_supply.high = 0

    return ()
end

@view
func test_pixel_erc721_mint{syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*}():
    tempvar pixel_contract_address
    %{ ids.pixel_contract_address = context.pixel_contract_address %}

    %{ stop_prank = start_prank(123456, target_contract_address=ids.pixel_contract_address) %}

    IPixelERC721.mint(contract_address=pixel_contract_address, to=123456)

    # Check that minted pixels count is 1

    let (total_supply : Uint256) = IPixelERC721.totalSupply(contract_address=pixel_contract_address)
    assert total_supply.low = 1
    assert total_supply.high = 0

    # Check that can't mint a second one

    %{ expect_revert(error_message="123456 already owns a pixel") %}

    IPixelERC721.mint(contract_address=pixel_contract_address, to=123456)

    %{ stop_prank() %}
    return ()
end

@view
func test_pixel_erc721_max_supply{
    syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*
}():
    tempvar pixel_contract_address
    %{ ids.pixel_contract_address = context.pixel_contract_address %}

    %{ stop_prank = start_prank(123456, target_contract_address=ids.pixel_contract_address) %}

    # Let's mint 3 more so we get to max supply

    IPixelERC721.mint(contract_address=pixel_contract_address, to=123456)
    IPixelERC721.mint(contract_address=pixel_contract_address, to=123457)
    IPixelERC721.mint(contract_address=pixel_contract_address, to=123458)
    IPixelERC721.mint(contract_address=pixel_contract_address, to=123459)

    # Check that minted pixels count is 4

    let (total_supply : Uint256) = IPixelERC721.totalSupply(contract_address=pixel_contract_address)
    assert total_supply.low = 4
    assert total_supply.high = 0

    # Check that once max supply is reached we can't mint anymore
    %{ expect_revert(error_message="Total pixel supply has already been minted") %}
    IPixelERC721.mint(contract_address=pixel_contract_address, to=123460)

    %{ stop_prank() %}
    return ()
end
