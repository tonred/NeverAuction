import inspect
from typing import Callable

import stringcase
from decohints import decohints
from tonos_ts4 import ts4

from utils.options import Options
from utils.wallet import Wallet

ANSWER_ID_KEY = 'answerId'


def _camelcase_dict(data: dict) -> dict:
    return {
        stringcase.camelcase(key): value
        for key, value in data.items()
    }


def _process_function_args(function: Callable, args: tuple, kwargs: dict, ignore: tuple = tuple()) -> (dict, Options):
    result = dict()
    # default values
    parameters = inspect.signature(function).parameters
    for parameter in parameters.values():
        if parameter.default != inspect.Parameter.empty:
            result[parameter.name] = parameter.default
    # kwargs values
    result.update(kwargs)
    # args values
    args_names = function.__code__.co_varnames[1:]  # skip self
    for name, arg in zip(args_names, args):
        result[name] = arg
    # pop options
    options = result.pop('options', None)
    # pop ignores
    for key in ignore:
        result.pop(key)
    # key names to camelcase
    result = _camelcase_dict(result)
    return result, options


def _find_sender(send_as: str, self: ts4.BaseContract, params: dict) -> Wallet:
    if hasattr(self, send_as):
        return getattr(self, send_as)
    return params.pop(send_as)


@decohints
def solidity_function(send_as: str = 'owner', ignore: tuple = ()):
    def decorator(function: Callable):
        def wrapper(self: ts4.BaseContract, *args, **kwargs):
            method = stringcase.camelcase(function.__name__)
            params, options = _process_function_args(function, args, kwargs, ignore)
            sender = _find_sender(send_as, self, params)
            print(method, params, options)
            sender.run_target(self, options=options, method=method, params=params)
            return function(self, *args, **kwargs)

        return wrapper

    return decorator


@decohints
def solidity_getter(responsible: bool = False):
    def decorator(function: Callable):
        def wrapper(self: ts4.BaseContract, *args, **kwargs):
            method = stringcase.camelcase(function.__name__)
            params, _ = _process_function_args(function, args, kwargs)
            if responsible:
                params[ANSWER_ID_KEY] = 0
            return self.call_getter(method, params)

        return wrapper

    return decorator
