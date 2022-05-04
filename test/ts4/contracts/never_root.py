from tonos_ts4 import ts4

from config import EMPTY_CELL, DEPLOY_WALLET_VALUE
from contracts.never_wallet import NeverWallet
from helpers.token_type import NEVER_ROOT
from utils.options import Options
from utils.solidity_function import solidity_function, solidity_getter
from utils.utils import ZERO_ADDRESS
from utils.wallet import Wallet


class NeverRoot(ts4.BaseContract):

    def __init__(self, elector: Wallet):
        wallet_code = ts4.load_code_cell('TestNeverWallet')
        wallet_platform_code = ts4.load_code_cell('TestNeverWalletPlatform')
        super().__init__(
            'TestNeverRoot',
            initial_data={
                'name_': 'Never',
                'symbol_': 'NEVER',
                'decimals_': 9,
                'rootOwner_': ZERO_ADDRESS,
                'walletCode_': wallet_code,
                'randomNonce_': 0,
                'deployer_': ZERO_ADDRESS,
                'platformCode_': wallet_platform_code,
            },
            ctor_params={
                'initialSupplyTo': ZERO_ADDRESS,
                'initialSupply': 0,
                'deployWalletValue': DEPLOY_WALLET_VALUE,
                'mintDisabled': False,
                'burnByRootDisabled': True,
                'burnPaused': False,
                'remainingGasTo': ZERO_ADDRESS,
                'owner': elector.address,
            },
            nickname='NeverRoot',
            override_address=NEVER_ROOT,
        )
        self.elector = elector

    @solidity_function(send_as='elector')
    def mint(
            self,
            amount: int,
            recipient: ts4.Address,
            deploy_wallet_value: int = DEPLOY_WALLET_VALUE,
            remaining_gas_to: int = ZERO_ADDRESS,
            notify: bool = True,
            payload: str = EMPTY_CELL,
            options: Options = Options(1),
    ):
        pass

    def get_wallet(self, owner: Wallet) -> NeverWallet:
        address = self.wallet_of(owner.address)
        return NeverWallet(address, self, owner)

    @solidity_getter(responsible=True)
    def wallet_of(self, wallet_owner: ts4.Address) -> ts4.Address:
        pass
