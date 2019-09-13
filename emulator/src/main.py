import click
import logging

from .cpu import CPU
from .nes import NES


log = logging.getLogger(__name__)


@click.command()
@click.argument("filename", type=click.File("rb"))
@click.option('-v', '--verbose', count=True)
def cli(filename, verbose):
    level = logging.WARNING - 10 * verbose
    logging.basicConfig(
        format="%(levelname)-10s - %(name)-20s - %(message)s", level=level
    )
    log.info("Started")


    log.debug("Loading cartridge")
    data = filename.read()

    cpu = CPU()
    nes = NES(cpu)

    nes.run(data)
