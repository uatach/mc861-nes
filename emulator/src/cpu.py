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

        self.opcodes = {
            0x0A: self._asl,
            0x18: self._clc,
            0x38: self._sec,
            0x85: self._sta,
            0x8D: self._sta,
            0xA5: self._lda,
            0xA9: self._lda,
            0xAD: self._lda,
        }

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
            self.pc = (self.pc + 1) % 2 ** 16
        print_status(self)

    def step(self):
        address = None
        instruction = self._read_word()

        log.debug("instruction: 0x%02X", instruction)
        # TODO: remove huge switch
        if instruction == 0x00:
            # TODO: needs better way to signal interruption
            raise Exception("brk")

        elif instruction in (0x0A, 0x18, 0x38):
            self.opcodes[instruction]()

        elif instruction == 0x4C:  # jmp
            self.pc = self._read_double()

        elif instruction == 0x85:  # sta zeropage
            address = self._read_word()
            self.opcodes[instruction](address)
        elif instruction == 0x8D:  # sta absolute
            address = self._read_double()
            self.opcodes[instruction](address)

        elif instruction == 0xA5:  # lda zeropage
            address = self._read_word()
            value = self.memory[address]
            self.opcodes[instruction](value)
        elif instruction == 0xA9:  # lda immediate
            value = self._read_word()
            self.opcodes[instruction](value)
        elif instruction == 0xAD:  # lda absolute
            address = self._read_double()
            value = self.memory[address]
            self.opcodes[instruction](value)

        print_status(self, address)

    def _read_word(self):
        value = self.memory[self.pc]
        self.__pc_increase()
        return value

    def _read_double(self):
        value = (self.memory[self.pc + 1] << 8) + self.memory[self.pc]
        self.__pc_increase()
        self.__pc_increase()
        return value

    def _asl(self):
        # set carry flag
        self.status |= (self.a & 0b10000000) >> 7
        # shift left
        self.a = (self.a << 1) & 0b11111111
        self.__check_flag_zero()
        self.__check_flag_negative()

    def _clc(self):
        self.status &= 0b11111110

    def _lda(self, value):
        self.a = value
        self.__check_flag_zero()
        self.__check_flag_negative()

    def _sec(self):
        self.status |= 0b00000001

    def _sta(self, address):
        self.memory[address] = self.a


    # private stuff

    def __pc_increase(self):
        self.pc = (self.pc + 1) % 2 ** 16

    def __check_flag_zero(self):
        if self.a == 0:
            self.status |= 0b00000010
        else:
            self.status &= 0b11111101

    def __check_flag_negative(self):
        if self.a & 0b10000000:
            self.status |= 0b10000000
