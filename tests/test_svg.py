"""test_svg.cairo test file."""
import os

import pytest
from starkware.starknet.testing.starknet import Starknet

from utils import felt_array_to_str, colors_list, str_to_single_felt



@pytest.mark.asyncio
async def test_svg():
    """Test svg method."""
    starknet = await Starknet.empty()

    svg_contract = await starknet.deploy(
        source=os.path.join("contracts", "svg.cairo"),
    )

    # try:
    #     execution_info = await svg_contract.get_svg(list(map(str_to_single_felt, colors_list[0:1000]))).call()
    # except Exception as e:
    #     assert "Pixel length must be 1024. Got: 1000" in e.message

    execution_info = await svg_contract.get_svg(list(map(str_to_single_felt, colors_list[0:2]))).call()
    assert felt_array_to_str(execution_info.result[0]) == 'data:image/svg+xml;utf8,<svg width="320" height="320" viewBox="0 0 320 320" xmlns="http://www.w3.org/2000/svg" shape-rendering="crispEdges"><rect width="10" height="10" x="0" y="0" fill="%23B0171F" /><rect width="10" height="10" x="10" y="0" fill="%23DC143C" /></svg>'
