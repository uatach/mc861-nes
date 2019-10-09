import attr
import logging

log = logging.getLogger(__name__)


def load(data):
    header = data[:16]
    banks = header[4]
    vbanks = header[5]
    prg_end = 0x4000 * banks + 16
    chr_end = 0x2000 * vbanks + prg_end
    prg_rom = data[16:prg_end]
    chr_rom = data[prg_end:chr_end]
    return header, prg_rom, chr_rom


@attr.s
class NES(object):
    cpu = attr.ib()
    ppu = attr.ib()
    bus = attr.ib()

    def setup(self, rom):
        # RAM mirroring
        self.bus.mirror(
            (0x0000, 0x0800), [(0x0800, 0x1000), (0x1000, 0x1800), (0x1800, 0x2000)]
        )

        size = len(rom)
        end = 0x10000
        start = end - size
        rom_range = start, end

        # copy rom data to memory
        self.bus.write_block(rom_range, rom)

        # ROM mirroring
        if size < 0x8000:
            self.bus.mirror(rom_range, [(start - size, start)])

        # PPU mirroring
        start = 0x2008
        mirrors = []
        for end in range(0x2010, 0x4001, 8):
            mirrors.append((start, end))
            start = end
        self.bus.mirror((0x2000, 0x2008), mirrors)

    def run(self, data):
        log.info("Running...")

        header, prg_rom, chr_rom = load(data)
        log.debug("Cartridge size: %s", hex(len(data)))
        log.debug("Header size: %s", hex(len(header)))
        log.debug("PRG size: %s", hex(len(prg_rom)))
        log.debug("CHR size: %s", hex(len(chr_rom)))

        self.bus.setup()
        self.setup(prg_rom)
        self.cpu.setup()
        self.ppu.setup()

        while True:
            try:
                self.cpu.step()
            except Exception as e:
                if str(e) != "brk":
                    raise e
                break
