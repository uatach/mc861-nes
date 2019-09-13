import attr


def print_status(cpu):
    print(
        "| pc = 0x{:04x} | a = 0x{:02x} | x = 0x{:02x} "
        "| y = 0x{:02x} | sp = 0x{:04x} | p[NV-BDIZC] = {:08b} |"
        " MEM[0x{:04x}] = 0x{:02x} |"
        "".format(cpu.pc, cpu.a, cpu.x, cpu.y, cpu.sp, cpu.status, cpu.pc, cpu.memory[cpu.pc])
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

    def setup(self, rom):
        # init empty memory
        self.memory = 2**16 * [0]

        # copy rom data to memory
        size = len(rom)
        start = 0x8000
        end = start + size
        self.memory[start:end] = rom

        # setup mirroring
        if size < 0x8000:
            start = end
            end = start + size
            self.memory[start:end] = rom

        # setting pc to the reset handler
        self.pc = (self.memory[0xfffa] << 8) + self.memory[0xfffb]

    def step(self):
        self.pc = (self.pc + 1) % 2**16
        print_status(self)
