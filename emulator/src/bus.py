import attr
import logging

log = logging.getLogger(__name__)


@attr.s
class BUS(object):
    def setup(self):
        self.memory = {}
        self.mirrors = {}

    def mirror(self, addr_range, mirrors):
        for m in mirrors:
            for target, origin in zip(range(*m), range(*addr_range)):
                self.mirrors[target] = origin
        log.debug("total mirrors: %s", hex(len(self.mirrors)))

    def read(self, addr, return_target=False):
        addr = self.mirrors.get(addr, addr)
        return self.memory[addr]

    def read_double(self, addr):
        addr = self.mirrors.get(addr, addr)
        high = (addr + 1) % 2 ** 16
        return (self.memory[high] << 8) + self.memory[addr]

    def read_target(self, addr):
        addr = self.mirrors.get(addr, addr)
        return addr, self.memory[addr]

    def write(self, addr, data):
        addr = self.mirrors.get(addr, addr)
        self.memory[addr] = data
        log.debug("memory size: %s", hex(len(self.memory)))
        return addr

    def write_block(self, block, data):
        for addr, value in zip(range(*block), data):
            addr = self.mirrors.get(addr, addr)
            self.memory[addr] = value
        log.debug("memory size: %s", hex(len(self.memory)))
