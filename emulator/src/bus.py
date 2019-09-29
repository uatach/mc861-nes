import attr
import logging

log = logging.getLogger(__name__)


@attr.s
class BUS(object):
    def __attrs_post_init__(self):
        self.memory = {}
        self.mirrors = {}

    def mirror(self, addr_range, mirrors):
        for m in mirrors:
            for target, origin in zip(range(*m), range(*addr_range)):
                self.mirrors[target] = origin
        log.debug("total mirrors: %s", hex(len(self.mirrors)))

    def write(self, addr_range, data):
        if isinstance(addr_range, tuple):
            for addr, value in zip(range(*addr_range), data):
                address = self.mirrors.get(addr, addr)
                self.memory[address] = value
            log.debug("memory size: %s", hex(len(self.memory)))
        else:
            address = self.mirrors.get(addr_range, addr_range)
            self.memory[address] = data
            log.debug("memory size: %s", hex(len(self.memory)))
            return address

    def read(self, addr):
        address = self.mirrors.get(addr, addr)
        return self.memory[address]

    def read_double(self, addr):
        address = self.mirrors.get(addr, addr)
        return (self.memory[address + 1] << 8) + self.memory[address]
