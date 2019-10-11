import attr

from .bus import Target


@attr.s
class MEM(Target):
    bus = attr.ib()

    def setup(self):
        self.cells = {}

        for i in range(2 ** 16):
            self.bus.attach(i, self)

    def read(self, addr):
        return self.cells.get(addr, 0)

    def write(self, addr, value):
        self.cells[addr] = value
