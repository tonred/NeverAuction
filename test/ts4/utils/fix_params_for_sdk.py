from tonos_ts4 import ts4


def fix_params_for_sdk(params: dict):
    """
    SDK have 2 known issues:
    1) Don't work correct big ints (they are converted to float)
    2) Don't accept ts4.Address type
    """
    for key, value in params.items():
        if isinstance(value, int) and value >= 2 * 32:
            params[key] = str(value)
        elif isinstance(value, ts4.Address):
            params[key] = value.str()
