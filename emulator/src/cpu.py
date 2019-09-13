import attr


def print_status(cpu):
    print(
        "| pc = 0x{:04x} | a = 0x{:02x} | x = 0x{:02x} "
        "| y = 0x{:02x} | sp = 0x{:04x} | p[NV-BDIZC] = {:08b} |"
        #" MEM[0xffff] = 0x99 |"
        "".format(cpu.pc, cpu.a, cpu.x, cpu.y, cpu.sp, cpu.status)
    )


@attr.s
class Register(object):
    value = 0

    def __get__(self, obj, type=None):
        return self.value

    def __set__(self, obj, value):
        self.value = value


@attr.s
class CPU(object):
    registers = dict()

    def __attrs_post_init__(self):
        # setting class properties
        for reg in ["pc", "a", "x", "y", "sp", "status"]:
            setattr(CPU, reg, Register())

    def __getitem__(self, key):
        return self.registers.get(key, 0)

    def setup(self, data):
        self.data = data

    def step(self):
        self.pc = (self.pc + 1) % 2**16
        print_status(self)
