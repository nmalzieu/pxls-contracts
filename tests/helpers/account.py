import os
from nile.signer import Signer, get_transaction_hash
from starkware.starknet.services.api.contract_class import ContractClass


async def deploy_account(starknet, public_key):
    return await starknet.deploy(
        contract_class=ContractClass.loads(
            data=open(
                os.path.join(os.path.dirname(__file__), "starknet_openzeppelin_account.json")
            ).read()
        ),
        constructor_calldata=[public_key],
    )


class AccountSigner:
    """
    Utility for sending signed transactions to an Account on Starknet.
    Parameters
    ----------
    private_key : int
    Examples
    ---------
    Constructing a AccountSigner object
    >>> signer = AccountSigner(1234)
    Sending a transaction
    >>> await signer.send_transaction(
            account, contract_address, 'contract_method', [arg_1]
        )
    Sending multiple transactions
    >>> await signer.send_transaction(
            account, [
                (contract_address, 'contract_method', [arg_1]),
                (contract_address, 'another_method', [arg_1, arg_2])
            ]
        )

    """

    def __init__(self, private_key):
        self.signer = Signer(private_key)
        self.public_key = self.signer.public_key

    async def send_transaction(
        self, account, to, selector_name, calldata, nonce=None, max_fee=0
    ):
        return await self.send_transactions(
            account, [(to, selector_name, calldata)], nonce, max_fee
        )

    async def send_transactions(self, account, calls, nonce=None, max_fee=0):
        if nonce is None:
            execution_info = await account.get_nonce().call()
            (nonce,) = execution_info.result

        build_calls = []
        for call in calls:
            build_call = list(call)
            build_call[0] = hex(build_call[0])
            build_calls.append(build_call)

        (call_array, calldata, sig_r, sig_s) = self.signer.sign_transaction(
            hex(account.contract_address), build_calls, nonce, max_fee
        )

        message_hash = get_transaction_hash(
            int(hex(account.contract_address), 16), call_array, calldata, nonce, max_fee
        )
        execution_info = await account.__execute__(call_array, calldata, nonce).invoke(
            signature=[sig_r, sig_s]
        )
        return message_hash, execution_info
