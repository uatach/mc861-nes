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

    def run(self, data):
        log.info("Running...")

        header, prg_rom, chr_rom = load(data)
        log.debug("Cartridge size: %d", len(data))
        log.debug("Header size: %d", len(header))
        log.debug("PRG size: %d", len(prg_rom))
        log.debug("CHR size: %d", len(chr_rom))

        self.cpu.setup(prg_rom)

        for _ in range(10):
            try:
                self.cpu.step()
            except Exception as e:
                log.error(e)
                break
