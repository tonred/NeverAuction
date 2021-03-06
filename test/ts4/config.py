import os

from tonos_ts4 import ts4

BUILD_ARTIFACTS_PATH = os.path.dirname(os.path.realpath(__file__)) + '/../../build/'
VERBOSE = os.getenv('TS4_VERBOSE', 'False').lower() == 'true'

EMPTY_CELL = ts4.Cell(ts4.EMPTY_CELL)

DAYS = 60 * 60 * 24

DEFAULT_FEE = ts4.GRAM
DEFAULT_DEPOSIT = 1000 * ts4.GRAM
DEFAULT_OPEN_DURATION = 7 * DAYS
DEFAULT_DE_BID_DURATION = 2 * DAYS
DEFAULT_CONFIRM_DURATION = 2 * DAYS
DEFAULT_SUB_OPEN_DURATION = DAYS
DEFAULT_SUB_CONFIRM_DURATION = DAYS
DEFAULT_MAKE_BID_DURATION = DAYS

ON_WIN_VALUE = int(0.5 * ts4.GRAM)
PERCENT_DENOMINATOR = 100_000

DEFAULT_DESCRIPTION = 'Test description 🤗'
DEFAULT_PRICES = {
    'min': int(0.35 * ts4.GRAM),
    'max': int(0.40 * ts4.GRAM),
}
DEFAULT_DEVIATION = 2_500  # 2.5%
DEFAULT_AGGREGATOR_FEE = 500  # 0.5%
DEFAULT_AGGREGATOR_VALUE = 120 * ts4.GRAM
DEFAULT_AGGREGATOR_MSG_VALUE = 123 * ts4.GRAM

DEFAULT_MIN_LOT_SIZE = 100
DEFAULT_QUOTING_PRICE = int(0.33 * ts4.GRAM)

DE_BID_TIME = DEFAULT_OPEN_DURATION
CONFIRM_TIME = DE_BID_TIME + DEFAULT_DE_BID_DURATION
FINISH_TIME = CONFIRM_TIME + DEFAULT_CONFIRM_DURATION
SUB_CONFIRM_TIME = DEFAULT_OPEN_DURATION
SUB_MAKE_BID_TIME = DEFAULT_OPEN_DURATION + DEFAULT_SUB_CONFIRM_DURATION

DEFAULT_BID_VALUE = DEFAULT_DEPOSIT // ts4.GRAM + 1
DEPLOY_WALLET_VALUE = int(0.2 * ts4.GRAM)
