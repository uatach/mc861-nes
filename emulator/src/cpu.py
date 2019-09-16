import attr
import logging

log = logging.getLogger(__name__)


def print_status(cpu, address=None):
    msg = (
        "| pc = 0x{:04x} | a = 0x{:02x} | x = 0x{:02x} "
        "| y = 0x{:02x} | sp = 0x{:04x} | p[NV-BDIZC] = {:08b} |"
        "".format(cpu.pc, cpu.a, cpu.x, cpu.y, cpu.sp, cpu.status)
    )
    if address is not None:
        msg += " MEM[0x{:04x}] = 0x{:02x} |".format(address, cpu.memory[address])
    print(msg)


@attr.s
class Register(object):
    value = 0

    def __get__(self, obj, type=None):
        return self.value

    def __set__(self, obj, value):
        self.value = value


@attr.s
class CPU(object):
    def __attrs_post_init__(self):
        # setting class properties
        for reg in ["pc", "a", "x", "y", "sp", "status"]:
            setattr(CPU, reg, Register())

    def setup(self, rom):
        # init empty memory
        self.memory = 2 ** 16 * [0]

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
        self.pc = (self.memory[0xFFFD] << 8) + self.memory[0xFFFC]

    def step1(self):
        address = None
        instruction = self.memory[self.pc]
        print("instruction", hex(instruction))
        if instruction == 0x4C:  # jump
            self.pc = (self.memory[self.pc + 2] << 8) + self.memory[self.pc + 1]
            print("jump absolute")
        else:
            if instruction == 0x69:  # adc immediate
                self.a = self.pc + 1
            elif instruction == 0x65:  # adc zero page
                self.a = self.memory[self.pc + 1]
            elif instruction == 0x29:  # and immediate
                self.a = self.pc + 1 & self.a
            elif instruction == 0x0A:  # asl accumulator
                self.a = self.a << 1
            self.pc = (self.pc + 1) % 2 ** 16
        print_status(self)

    def step(self):
        address = None
        instruction = self.memory[self.pc]
        log.debug("instruction: 0x%02x", instruction)

        if instruction == 0x00:
            raise Exception("brk")
        elif instruction == 0xA5:
            self.pc = (self.pc + 1) % 2 ** 16
            address = self.memory[self.pc]
            self.a = self.memory[address]

            if self.a == 0:
                self.status |= 0b00000010
            else:
                self.status &= 0b11111101

            if self.a & 0b10000000:
                self.status |= 0b10000000

            self.pc = (self.pc + 1) % 2 ** 16
        elif instruction == 0xA9:
            self.pc = (self.pc + 1) % 2 ** 16
            self.a = self.memory[self.pc]

            if self.a == 0:
                self.status |= 0b00000010
            else:
                self.status &= 0b11111101

            if self.a & 0b10000000:
                self.status |= 0b10000000

            self.pc = (self.pc + 1) % 2 ** 16
        elif instruction == 0x4C:
            self.pc = (self.memory[self.pc + 2] << 8) + self.memory[self.pc + 1]
        else:
            self.pc = (self.pc + 1) % 2 ** 16

        print_status(self, address)
