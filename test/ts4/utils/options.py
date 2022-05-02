from dataclasses import dataclass

from tonos_ts4 import ts4


@dataclass(frozen=True)
class Options:
    value: float
    flag: int = 1
    bounce: bool = False
    expect_ec: int = 0

    @classmethod
    def from_grams(cls, grams: int, **kwargs) -> 'Options':
        return cls(grams / ts4.GRAM, **kwargs)

    @property
    def grams(self) -> int:
        return int(self.value * ts4.GRAM)
