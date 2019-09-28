import attr
import logging

log = logging.getLogger(__name__)


@attr.s
class BUS(object):
    memory = 2 ** 16 * [0]

    def mirror(self, addr_range, mirrors):
        for m in mirrors:
            self.memory[m] = self.memory[addr_range]

    def write(self, addr_range, data):
        self.memory[addr_range] = data

    def read(self, addr):
        value = self.memory[addr]
        return value

    def read_double(self, addr):
        return (self.read(addr + 1) << 8) + self.read(addr)
