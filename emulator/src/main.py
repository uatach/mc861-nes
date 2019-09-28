import click
import logging

from .bus import BUS
from .cpu import CPU
from .nes import NES


log = logging.getLogger(__name__)


@click.command()
@click.argument("filename", type=click.File("rb"))
@click.option("-v", "--verbose", count=True, help="Increase verbosity.")
def cli(filename, verbose):
    level = logging.WARNING - 10 * verbose
    logging.basicConfig(
        format="%(levelname)-10s - %(name)-20s - %(message)s", level=level
    )
    log.info("Started")

    log.debug("Loading cartridge")
    data = filename.read()

    # TODO: share memory with the ppu
    memory = 2 ** 16 * [0]

    bus = BUS()
    ppu = None
    cpu = CPU(memory)
    nes = NES(cpu, ppu, bus)

    nes.run(data)
