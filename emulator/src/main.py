import click
import logging

from .bus import BUS
from .cpu import CPU
from .mem import MEM
from .nes import NES
from .ppu import PPU


log = logging.getLogger(__name__)


@click.command()
@click.argument("filename", type=click.File("rb"))
@click.option("-v", "--verbose", count=True, help="Increase verbosity.")
@click.option("--headless", is_flag=True, help="Hide game window.")
def cli(filename, headless, verbose):
    level = logging.WARNING - 10 * verbose
    logging.basicConfig(
        format="%(levelname)-10s - %(name)-20s - %(message)s", level=level
    )
    log.info("Started")

    log.debug("Loading cartridge")
    data = filename.read()

    bus = BUS()
    mem = MEM(bus)
    cpu = CPU(bus)
    ppu = PPU(bus, headless)
    nes = NES(bus, mem, cpu, ppu)

    nes.run(data)
