import attr
import pygame

from .bus import Target


@attr.s
class PPU(Target):
    bus = attr.ib()
    headless = attr.ib(False)

    def setup(self):
        self.registers = {}

        self.bus.attach(0x2000, self)
        self.bus.attach(0x2001, self)
        self.bus.attach(0x2002, self)
        self.bus.attach(0x2003, self)
        self.bus.attach(0x2004, self)
        self.bus.attach(0x2005, self)
        self.bus.attach(0x2006, self)
        self.bus.attach(0x2007, self)
        self.bus.attach(0x4014, self)

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

    def read(self, addr):
        return self.registers.get(addr, 0)

    def write(self, addr, value):
        self.registers[addr] = value

    def step(self):
        if not self.headless:
            self.screen.fill((0, 0, 0))
            pygame.display.flip()

        self.write(0x2002, 0b10000000)
