"""pynesemu - NES emulator"""

import logging

try:
    from .main import cli
except:  # pragma: no cover
    pass

__name__ = "pynesemu"
__version__ = "0.7.1"

logging.getLogger(__name__).addHandler(logging.NullHandler())
