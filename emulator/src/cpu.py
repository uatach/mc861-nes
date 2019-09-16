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
            0x00: self._brk,
            0x0A: self._asl,
            0x18: self._clc,
            0x29: self._and_imm,
            0x38: self._sec,
            0x4C: self._jmp_abs,
            0x6C: self._jmp_ind,
            0x65: self._adc_zp,
            0x69: self._adc_imm,
            0x85: self._sta_zp,
            0x8D: self._sta_abs,
            0xA2: self._ldx_imm,
            0xA5: self._lda_zp,
            0xA6: self._ldx_zp,
            0xA9: self._lda_imm,
            0xAD: self._lda_abs,
            0xAE: self._ldx_abs,
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

    def step(self):
        instruction = self._read_word()
        log.debug("instruction: 0x%02X", instruction)

        address = self.opcodes[instruction]()
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

    def _adc_imm(self):
        # FIXME:
        self.a = self.pc + 1

    def _adc_zp(self):
        # FIXME:
        self.a = self.memory[self.pc + 1]

    def _and_imm(self):
        # FIXME:
        self.a = self.pc + 1 & self.a

    def _asl(self):
        # set carry flag
        self.status |= (self.a & 0b10000000) >> 7
        # shift left
        self.a = (self.a << 1) & 0b11111111
        self.__check_flag_zero()
        self.__check_flag_negative()

    def _brk(self):
        # TODO: needs better way to signal interruption
        raise Exception("brk")

    def _clc(self):
        self.status &= 0b11111110

    def _jmp_abs(self):
        self.pc = self._read_double()

    def _jmp_ind(self):
        address = self._read_double()
        value = (self.memory[address + 1] << 8) + self.memory[address]
        self.pc = value

    def _lda_imm(self):
        self.a = self._read_word()
        self.__check_flag_zero()
        self.__check_flag_negative()

    def _lda_abs(self):
        address = self._read_double()
        self.a = self.memory[address]
        self.__check_flag_zero()
        self.__check_flag_negative()
        return address

    def _lda_zp(self):
        address = self._read_word()
        self.a = self.memory[address]
        self.__check_flag_zero()
        self.__check_flag_negative()
        return address

    def _ldx_abs(self):
        address = self._read_double()
        self.x = self.memory[address]
        self.__check_flag_zero()
        self.__check_flag_negative()
        return address

    def _ldx_imm(self):
        self.x = self._read_word()
        self.__check_flag_zero()
        self.__check_flag_negative()

    def _ldx_zp(self):
        address = self._read_word()
        self.x = self.memory[address]
        self.__check_flag_zero()
        self.__check_flag_negative()
        return address

    def _sec(self):
        self.status |= 0b00000001

    def _sta_abs(self):
        address = self._read_double()
        self.memory[address] = self.a
        return address

    def _sta_zp(self):
        address = self._read_word()
        self.memory[address] = self.a
        return address

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
