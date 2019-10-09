import attr
import pygame

from .register import Register


@attr.s
class PPU(object):
    bus = attr.ib()
    headless = attr.ib(False)

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

        # pygame setup
        if not self.headless:
            pygame.init()
            self.screen = pygame.display.set_mode([640, 480])
            pygame.display.set_caption("pynesemu")

    def step(self):
        if not self.headless:
            self.screen.fill(BLACK)
            pygame.display.flip()
