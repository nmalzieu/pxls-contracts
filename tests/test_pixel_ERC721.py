"""test_svg.cairo test file."""
import os
import asyncio

import pytest
from starkware.starknet.testing.starknet import Starknet

from helpers.account import AccountSigner, deploy_account
from helpers.types import str_to_felt, to_uint
from helpers.vm import assert_revert

signer = AccountSigner(123456789987654321)


@pytest.fixture(scope="module")
def event_loop():
    loop = asyncio.get_event_loop()
    yield loop
    loop.close()


class Setup:
    starknet = None
    account = None
    pixel_contract = None


@pytest.fixture(scope="module")
async def setup():
    starknet = await Starknet.empty()

    account = await deploy_account(starknet, signer.public_key)

    pixel_contract = await starknet.deploy(
        source=os.path.join("contracts", "PixelERC721.cairo"),
        constructor_calldata=[
            str_to_felt("Pixel"),  # name
            str_to_felt("PXL"),  # symbol
            account.contract_address,  # owner
            *to_uint(2),  # matrix_size 2 x 2 => 4 pixels
        ],
    )

    s = Setup()
    s.pixel_contract = pixel_contract
    s.account = account
    s.starknet = starknet

    return s


@pytest.mark.asyncio
async def test_pixel_erc721_initializable(setup: Setup):

    # Drawer address must be 0

    execution_info = await setup.pixel_contract.pixelDrawerAddress().call()
    assert execution_info.result == (0,)

    # Set drawer address

    await signer.send_transaction(
        setup.account,
        setup.pixel_contract.contract_address,
        "initialize",
        [654321],
    )

    # Drawer address must be 654321

    execution_info = await setup.pixel_contract.pixelDrawerAddress().call()
    assert execution_info.result == (654321,)

    # Drawer address cannot be set again

    await assert_revert(
        signer.send_transaction(
            setup.account,
            setup.pixel_contract.contract_address,
            "initialize",
            [123456],
        ),
        reverted_with="Pixel contract already initialized",
    )


@pytest.mark.asyncio
async def test_pixel_erc721_getters(setup: Setup):

    execution_info = await setup.pixel_contract.matrixSize().call()
    assert execution_info.result == (to_uint(2),)

    execution_info = await setup.pixel_contract.maxSupply().call()
    assert execution_info.result == (to_uint(4),)

    # Check that minted pixels count is 0

    execution_info = await setup.pixel_contract.totalSupply().call()
    assert execution_info.result == (to_uint(0),)


@pytest.mark.asyncio
async def test_pixel_erc721_mint(setup: Setup):

    # Mint first token

    await signer.send_transaction(
        setup.account,
        setup.pixel_contract.contract_address,
        "mint",
        [setup.account.contract_address],
    )

    # Check that pixelsCount has increased

    execution_info = await setup.pixel_contract.totalSupply().call()
    assert execution_info.result == (to_uint(1),)


@pytest.mark.asyncio
async def test_pixel_erc721_max_supply(setup: Setup):

    # Let's mint 3 more so we get to max supply
    for i in range(0, 3):
        await signer.send_transaction(
            setup.account,
            setup.pixel_contract.contract_address,
            "mint",
            [setup.account.contract_address],
        )

    execution_info = await setup.pixel_contract.totalSupply().call()
    assert execution_info.result == (to_uint(4),)

    # Check that once max supply is reached we can't mint anymore
    await assert_revert(
        signer.send_transaction(
            setup.account,
            setup.pixel_contract.contract_address,
            "mint",
            [setup.account.contract_address],
        ),
        reverted_with="Total pixel supply has already been minted",
    )
