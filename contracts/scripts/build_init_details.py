from typing import List

from tonclient.test.helpers import sync_core_client
from tonclient.types import ParamsOfAbiEncodeBoc, AbiParam

TIP3_ABI_PARAMS = [
    AbiParam('neverRoot', type='address'),
    AbiParam('neverWallet', type='address'),
]
ECC_ABI_PARAMS = [
    AbiParam('neverID', type='uint32'),
    AbiParam('electorVault', type='address'),
]


def encode_boc(abi_params: List[AbiParam], data: dict):
    params_encode_boc = ParamsOfAbiEncodeBoc(
        params=abi_params,
        data=data,
    )
    encoded_boc = sync_core_client.abi.encode_boc(params_encode_boc)
    print(f'Initial details TvmCell in base64: {encoded_boc.boc}')


def build_for_tip3():
    never_root = input('Never root address: ')
    never_wallet = input('Never wallet address: ')
    encode_boc(TIP3_ABI_PARAMS, data={
        'neverRoot': never_root,
        'neverWallet': never_wallet,
    })


def build_for_ecc():
    never_id = int(input('Never ECC ID: '))
    elector_value = input('Elector vault address: ')
    encode_boc(ECC_ABI_PARAMS, data={
        'neverID': never_id,
        'electorVault': elector_value,
    })


def main():
    type_id = 0
    while type_id not in (1, 2):
        type_id = int(input(
            'Choose type:\n'
            '1) Via TIP3 (TIP3.1 standard)\n'
            '2) Via ECC (extra currency collection)\n'
            'Type (1 or 2): '
        ))
    build_for_tip3() if type_id == 1 else build_for_ecc()


if __name__ == '__main__':
    main()
