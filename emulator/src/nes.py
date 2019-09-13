import attr
import logging

log = logging.getLogger(__name__)


@attr.s
class NES(object):
    cpu = attr.ib()

    def run(self, data):
        log.info("Running...")
        log.debug("Cartridge size: %d", len(data))

        prg = None
        self.cpu.setup(prg)

        while True:
            self.cpu.step()
