import json

from tonclient.test.helpers import sync_core_client
from tonclient.types import Abi, Signer, CallSet, ParamsOfEncodeMessageBody
from tonos_ts4 import ts4

from config import EMPTY_CELL
from utils.fix_params_for_sdk import fix_params_for_sdk
from utils.options import Options
from utils.utils import random_address


class Wallet(ts4.BaseContract):

    def __init__(self, nickname: str = 'Wallet', balance: int = 10000 * ts4.GRAM):
        super().__init__(
            'Wallet',
            {},
            nickname=nickname,
            override_address=random_address(),
            keypair=ts4.make_keypair(),
            balance=balance,
        )

    def run_target(
            self,
            contract: ts4.BaseContract,
            options: Options,
            method: str,
            params: dict = None,
    ):
        fix_params_for_sdk(params)
        call_set = CallSet(method, input=params)
        self.send_call_set(contract.address, options, call_set, contract.abi.json)

    def send_call_set(
            self,
            dest: ts4.Address,
            options: Options,
            call_set: CallSet,
            abi: dict,
    ):
        encode_params = ParamsOfEncodeMessageBody(
            abi=Abi.Json(json.dumps(abi)),
            signer=Signer.NoSigner(),
            call_set=call_set,
            is_internal=True,
        )
        message = sync_core_client.abi.encode_message_body(params=encode_params)
        payload = ts4.Cell(message.body)
        self.send_transaction(dest, options, payload=payload)

    def send_transaction(
            self,
            destination: ts4.Address,
            options: Options,
            payload: ts4.Cell = EMPTY_CELL,
    ):
        self.call_method('sendTransaction', {
            'dest': destination,
            'value': options.grams,
            'flags': options.flag,
            'bounce': options.bounce,
            'payload': payload,
        }, private_key=self.private_key_)
        ts4.dispatch_one_message(expect_ec=options.expect_ec)
        ts4.dispatch_messages()
