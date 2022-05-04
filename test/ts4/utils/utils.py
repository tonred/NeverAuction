import random
import string

from tonos_ts4 import ts4

ZERO_ADDRESS = ts4.Address.zero_addr()
HEXDIGITS = string.digits + 'abcdef'


def random_address() -> ts4.Address:
    address = '0:' + ''.join(random.choices(HEXDIGITS, k=64))
    return ts4.Address(address)


def random_salt() -> int:
    return random.randint(0, 2 ** 256 - 1)
