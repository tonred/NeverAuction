import typing

from tonos_ts4 import ts4

from utils.base_contract import BaseContract
from utils.solidity_function import solidity_getter
from utils.wallet import Wallet

if typing.TYPE_CHECKING:
    from contracts.never_root import NeverRoot


class NeverWallet(BaseContract):

    def __init__(self, address: ts4.Address, root: 'NeverRoot', owner: Wallet):
        super().__init__(address, abi_name='TestNeverWallet')
        self.root = root
        self.owner = owner

    @solidity_getter(responsible=True)
    def balance(self) -> int:
        pass
