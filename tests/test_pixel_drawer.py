"""test_svg.cairo test file."""
import os
import asyncio

import pytest
from starkware.starknet.testing.starknet import Starknet

from helpers.account import AccountSigner, deploy_account
from helpers.types import str_to_felt, felt_to_clean_str, to_uint
from helpers.vm import assert_revert

signer = AccountSigner(123456789987654321)


@pytest.fixture(scope="module")
def event_loop():
    loop = asyncio.get_event_loop()
    yield loop
    loop.close()


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
        [drawer_contract.contract_address], # pixel_drawer_address
    )

    return (starknet, account, pixel_contract, drawer_contract)


@pytest.mark.asyncio
async def test_pixel_drawer_getters(setup):
    _, _, pixel_contract, drawer_contract = setup

    execution_info = await drawer_contract.pixelERC721Address().call()
    assert execution_info.result == (pixel_contract.contract_address,)

    execution_info = await pixel_contract.pixelDrawerAddress().call()
    assert execution_info.result == (drawer_contract.contract_address,)
