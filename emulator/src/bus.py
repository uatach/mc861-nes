import attr
import logging

log = logging.getLogger(__name__)


@attr.s
class BUS(object):
    def __attrs_post_init__(self):
        self.memory = 2 ** 16 * [0]

    def mirror(self, addr_range, mirrors):
        for m in mirrors:
            self.memory[slice(*m)] = self.memory[slice(*addr_range)]

    def write(self, addr_range, data):
        if isinstance(addr_range, tuple):
            self.memory[slice(*addr_range)] = data
        else:
            self.memory[addr_range] = data

    def read(self, addr):
        return self.memory[addr]

    def read_double(self, addr):
        return (self.read(addr + 1) << 8) + self.read(addr)
