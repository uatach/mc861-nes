import attr
import logging

log = logging.getLogger(__name__)


@attr.s
class Target(object):
    def get(self):
        raise NotImplementedError

    def set(self, value):
        raise NotImplementedError


@attr.s
class BUS(object):
    def setup(self):
        self.mirrors = {}
        self.targets = {}

    def attach(self, addr, target):
        assert isinstance(target, Target)
        self.targets[addr] = target

    def mirror(self, addr_range, mirrors):
        for m in mirrors:
            for target, origin in zip(range(*m), range(*addr_range)):
                self.mirrors[target] = origin
        log.debug("total mirrors: %s", hex(len(self.mirrors)))

    def read(self, addr):
        addr = self.mirrors.get(addr, addr)
        value = self.targets[addr].get()
        return value

    def read_double(self, addr):
        addr = self.mirrors.get(addr, addr)
        high = (addr + 1) % 2 ** 16
        value = self.targets[high].get() << 8
        value += self.targets[addr].get()
        return value

    def read_target(self, addr):
        addr = self.mirrors.get(addr, addr)
        value = self.targets[addr].get()
        return addr, value

    def write(self, addr, data):
        addr = self.mirrors.get(addr, addr)
        self.targets[addr].set(data)
        return addr

    def write_block(self, block, data):
        for addr, value in zip(range(*block), data):
            addr = self.mirrors.get(addr, addr)
            self.targets[addr].set(value)
