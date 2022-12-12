import asyncio
from starknet_py.net.gateway_client import GatewayClient

local_network_client = GatewayClient("http://localhost:5000")


async def go():
    call_result = await local_network_client


asyncio.run(go())