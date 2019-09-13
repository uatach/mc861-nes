import attr


def print_status(cpu):
    print(
        "| pc = 0x{:04x} | a = 0x{:02x} | x = 0x{:02x} "
        "| y = 0x{:02x} | sp = 0x{:04x} | p[NV-BDIZC] = {:08b} |"
        "".format(cpu.pc, cpu.a, cpu.x, cpu.y, cpu.sp, cpu.status)
    )


@attr.s
class CPU(object):
    registers = dict()

    def __attrs_post_init__(self):
        # setting class properties
        for reg in ["pc", "a", "x", "y", "sp", "status"]:
            setattr(CPU, reg, property(lambda self: self[reg]))

    def __getitem__(self, key):
        return self.registers.get(key, 0)

    def setup(self, data):
        pass

    def step(self):
        print_status(self)
