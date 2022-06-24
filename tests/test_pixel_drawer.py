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
    drawer_contract = None


MATRIX_SIZE = 20


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
            *to_uint(MATRIX_SIZE),  # matrix_size 2 x 2 => 4 pixels
        ],
    )

    drawer_contract = await starknet.deploy(
        source=os.path.join("contracts", "PixelDrawer.cairo"),
        constructor_calldata=[
            pixel_contract.contract_address,  # pixel_erc721_address
            account.contract_address,  # owner
        ],
    )

    await signer.send_transaction(
        account,
        pixel_contract.contract_address,
        "initialize",
        [drawer_contract.contract_address],  # pixel_drawer_address
    )

    s = Setup()
    s.drawer_contract = drawer_contract
    s.pixel_contract = pixel_contract
    s.account = account
    s.starknet = starknet

    return s


@pytest.mark.asyncio
async def test_pixel_drawer_getters(setup: Setup):
    execution_info = await setup.drawer_contract.pixelERC721Address().call()
    assert execution_info.result == (setup.pixel_contract.contract_address,)

    execution_info = await setup.pixel_contract.pixelDrawerAddress().call()
    assert execution_info.result == (setup.drawer_contract.contract_address,)

    execution_info = await setup.drawer_contract.currentDrawingTimestamp().call()
    # Timestamp is returning 0 right now, to test on devnet
    assert execution_info.result == (0,)


@pytest.mark.asyncio
async def test_pixel_drawer_pixel_owner(setup: Setup):
    # I can't draw non existing pixel
    await assert_revert(
        signer.send_transaction(
            setup.account,
            setup.drawer_contract.contract_address,
            "setPixelColor",
            [*to_uint(1), *(255, 0, 0)],
        ),
        reverted_with="ERC721: owner query for nonexistent token",
    )

    # Minting first pixel
    await signer.send_transaction(
        setup.account,
        setup.pixel_contract.contract_address,
        "mint",
        [setup.account.contract_address],
    )

    account_2 = await deploy_account(setup.starknet, signer.public_key)

    # Non owner can't draw pixel
    await assert_revert(
        signer.send_transaction(
            account_2,
            setup.drawer_contract.contract_address,
            "setPixelColor",
            [*to_uint(1), *(255, 0, 0)],
        ),
        reverted_with="Address does not own pixel",
    )


@pytest.mark.asyncio
async def test_pixel_drawer_pixel_color(setup: Setup):
    # Check pixel color getter

    execution_info = await setup.drawer_contract.pixelColor(to_uint(1)).call()
    assert execution_info.result == ((0, (0, 0, 0)),)  # First int 0 = unset, rest = rgb

    # Pixel owner cannot draw pixel with wrong color
    await assert_revert(
        signer.send_transaction(
            setup.account,
            setup.drawer_contract.contract_address,
            "setPixelColor",
            [*to_uint(1), *(265, 0, 0)],  # rgb
        )
    )

    # Pixel owner can draw pixel with right color
    await signer.send_transaction(
        setup.account,
        setup.drawer_contract.contract_address,
        "setPixelColor",
        [*to_uint(1), *(250, 0, 0)],
    )

    # Check pixel color has been set
    execution_info = await setup.drawer_contract.pixelColor(to_uint(1)).call()
    assert execution_info.result == ((1, (250, 0, 0)),)  # First int 1 = set, rest = rgb

    # Pixel owner can draw pixel again
    await signer.send_transaction(
        setup.account,
        setup.drawer_contract.contract_address,
        "setPixelColor",
        [*to_uint(1), *(0, 0, 0)],
    )

    # Check pixel color has been set
    execution_info = await setup.drawer_contract.pixelColor(to_uint(1)).call()
    assert execution_info.result == ((1, (0, 0, 0)),)  # First int 1 = set, rest = rgb


@pytest.mark.asyncio
async def test_pixel_drawer_shuffle_result(setup: Setup):
    # Check pixel shuffle
    execution_info = await setup.drawer_contract.tokenPixelIndex(to_uint(1)).call()
    # For a given matrix size, result is deterministic
    # For 20x20, first token position is 378 = 1 * 373 + 5 % 400
    assert execution_info.result == (378,)
