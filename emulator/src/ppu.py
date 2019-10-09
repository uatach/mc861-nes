import attr

from .register import Register


@attr.s
class PPU(object):
    bus = attr.ib()

    ppuctrl = Register()
    ppumask = Register()
    ppustatus = Register()
    oamaddr = Register()
    oamdata = Register()
    ppuscroll = Register()
    ppuaddr = Register()
    ppudata = Register()
    oamdma = Register()

    def setup(self):
        start = 0x2008
        mirrors = []
        for end in range(0x2010, 0x4001, 8):
            mirrors.append((start, end))
            start = end
        self.bus.mirror((0x2000, 0x2008), mirrors)

    def step(self):
        pass
