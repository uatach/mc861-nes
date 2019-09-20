"""pynesemu - NES emulator"""

import logging

try:
    from .main import cli
except:  # pragma: no cover
    pass

__name__ = "pynesemu"
__version__ = "0.2.0"

logging.getLogger(__name__).addHandler(logging.NullHandler())
