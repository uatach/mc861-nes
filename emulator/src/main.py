import click
import logging

from .nes import NES


@click.command()
@click.argument("filename", type=click.File("rb"))
def cli(filename):
    data = filename.read()

    nes = NES()

    nes.run(data)
