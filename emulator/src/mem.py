import attr

from .bus import Target


@attr.s
class Cell(Target):
    value = attr.ib(None)

    def get(self):
        return self.value

    def set(self, value):
        self.value = value


@attr.s
class MEM(object):
    bus = attr.ib()
    cells = attr.ib(factory=list)

    def setup(self):
        # FIXME: there is no need for this many cells
        for i in range(2 ** 16):
            cell = Cell(0)
            self.cells.append(cell)
            self.bus.attach(i, cell)
