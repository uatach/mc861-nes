import attr
import logging

log = logging.getLogger(__name__)


def dec(value):
    return (value - 1) % 2 ** 8


def inc(value, size=8):
    return (value + 1) % 2 ** size


def two_complements(value):
    if value & (1 << 7):
        return value - (1 << 8)
    return value


def print_status(cpu, address=None):
    msg = (
        "| pc = 0x{:04x} | a = 0x{:02x} | x = 0x{:02x} "
        "| y = 0x{:02x} | sp = 0x{:04x} | p[NV-BDIZC] = {:08b} |"
        "".format(cpu.pc, cpu.a, cpu.x, cpu.y, cpu.sp, cpu.status)
    )
    if address is not None:
        address, value = cpu.bus.read_target(address)
        msg += " MEM[0x{:04x}] = 0x{:02x} |".format(address, value)
    print(msg)


def log_value(value):
    log.debug("value: 0b{:08b} - 0x{:02x} - {:03d}".format(value, value, value))


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
            0x01: self._ora_indx,
            0x05: self._ora_zp,
            0x06: self._asl_zp,
            0x08: self._php,
            0x09: self._ora_imm,
            0x0A: self._asl_acc,
            0x0D: self._ora_abs,
            0x0E: self._asl_abs,
            0x10: self._bpl,
            0x11: self._ora_indy,
            0x15: self._ora_zpx,
            0x16: self._asl_zpx,
            0x18: self._clc,
            0x19: self._ora_absy,
            0x1D: self._ora_absx,
            0x1E: self._asl_absx,
            0x20: self._jsr,
            0x21: self._and_indx,
            0x24: self._bit_zp,
            0x25: self._and_zp,
            0x26: self._rol_zp,
            0x28: self._plp,
            0x29: self._and_imm,
            0x2A: self._rol_acc,
            0x2C: self._bit_abs,
            0x2D: self._and_abs,
            0x2E: self._rol_abs,
            0x30: self._bmi,
            0x31: self._and_indy,
            0x35: self._and_zpx,
            0x36: self._rol_zpx,
            0x38: self._sec,
            0x39: self._and_absy,
            0x3D: self._and_absx,
            0x3E: self._rol_absx,
            0x40: self._rti,
            0x41: self._eor_indx,
            0x45: self._eor_zp,
            0x46: self._lsr_zp,
            0x48: self._pha,
            0x49: self._eor_imm,
            0x4A: self._lsr_acc,
            0x4C: self._jmp_abs,
            0x4D: self._eor_abs,
            0x4E: self._lsr_abs,
            0x50: self._bvc,
            0x51: self._eor_indy,
            0x55: self._eor_zpx,
            0x56: self._lsr_zpx,
            0x58: self._cli,
            0x59: self._eor_absy,
            0x5D: self._eor_absx,
            0x5E: self._lsr_absx,
            0x60: self._rts,
            0x61: self._adc_indx,
            0x65: self._adc_zp,
            0x66: self._ror_zp,
            0x68: self._pla,
            0x69: self._adc_imm,
            0x6A: self._ror_acc,
            0x6C: self._jmp_ind,
            0x6D: self._adc_abs,
            0x6E: self._ror_abs,
            0x70: self._bvs,
            0x71: self._adc_indy,
            0x75: self._adc_zpx,
            0x76: self._ror_zpx,
            0x78: self._sei,
            0x79: self._adc_absy,
            0x7D: self._adc_absx,
            0x7E: self._ror_absx,
            0x81: self._sta_indx,
            0x84: self._sty_zp,
            0x85: self._sta_zp,
            0x86: self._stx_zp,
            0x88: self._dey,
            0x8A: self._txa,
            0x8C: self._sty_abs,
            0x8D: self._sta_abs,
            0x8E: self._stx_abs,
            0x90: self._bcc,
            0x91: self._sta_indy,
            0x94: self._sty_zpx,
            0x95: self._sta_zpx,
            0x96: self._stx_zpy,
            0x98: self._tya,
            0x99: self._sta_absy,
            0x9A: self._txs,
            0x9D: self._sta_absx,
            0xA0: self._ldy_imm,
            0xA1: self._lda_indx,
            0xA2: self._ldx_imm,
            0xA4: self._ldy_zp,
            0xA5: self._lda_zp,
            0xA6: self._ldx_zp,
            0xA8: self._tay,
            0xA9: self._lda_imm,
            0xAA: self._tax,
            0xAC: self._ldy_abs,
            0xAD: self._lda_abs,
            0xAE: self._ldx_abs,
            0xB0: self._bcs,
            0xB1: self._lda_indy,
            0xB4: self._ldy_zpx,
            0xB5: self._lda_zpx,
            0xB6: self._ldx_zpy,
            0xB8: self._clv,
            0xB9: self._lda_absy,
            0xBA: self._tsx,
            0xBC: self._ldy_absx,
            0xBD: self._lda_absx,
            0xBE: self._ldx_absy,
            0xC0: self._cpy_imm,
            0xC1: self._cmp_indx,
            0xC4: self._cpy_zp,
            0xC5: self._cmp_zp,
            0xC6: self._dec_zp,
            0xC8: self._iny,
            0xC9: self._cmp_imm,
            0xCA: self._dex,
            0xCC: self._cpy_abs,
            0xCD: self._cmp_abs,
            0xCE: self._dec_abs,
            0xD0: self._bne,
            0xD1: self._cmp_indy,
            0xD5: self._cmp_zpx,
            0xD6: self._dec_zpx,
            0xD8: self._cld,
            0xD9: self._cmp_absy,
            0xDD: self._cmp_absx,
            0xDE: self._dec_absx,
            0xE0: self._cpx_imm,
            0xE1: self._sbc_indx,
            0xE4: self._cpx_zp,
            0xE5: self._sbc_zp,
            0xE6: self._inc_zp,
            0xE8: self._inx,
            0xE9: self._sbc_imm,
            0xEA: self._nop,
            0xEC: self._cpx_abs,
            0xED: self._sbc_abs,
            0xEE: self._inc_abs,
            0xF0: self._beq,
            0xF1: self._sbc_indy,
            0xF5: self._sbc_zpx,
            0xF6: self._inc_zpx,
            0xF8: self._sed,
            0xF9: self._sbc_absy,
            0xFD: self._sbc_absx,
            0xFE: self._inc_absx,
        }
        log.info("Handling %d opcodes", len(self.opcodes))

    def setup(self, bus, rom):
        self.bus = bus

        # RAM mirroring
        self.bus.mirror(
            (0x0000, 0x0800), [(0x0800, 0x1000), (0x1000, 0x1800), (0x1800, 0x2000)]
        )

        size = len(rom)
        start = 0x8000
        end = start + size
        rom_range = start, end

        # copy rom data to memory
        self.bus.write_block(rom_range, rom)

        # ROM mirroring
        if size < 0x8000:
            self.bus.mirror(rom_range, [(end, end + size)])

        # PPU mirroring
        start = 0x2008
        mirrors = []
        for end in range(0x2010, 0x4001, 8):
            mirrors.append((start, end))
            start = end
        self.bus.mirror((0x2000, 0x2008), mirrors)

        # setting inital state as seen at the docs at:
        #  https://docs.google.com/document/d/1-9duwtoaHSB290ANLHiyDz7mwlN425e_aiLzmIjW1S8
        self.status = 0x34
        self.a, self.x, self.y = 0, 0, 0
        self.sp = 0x01FD
        self.bus.write_block((0x0000, 0x07FF), 0x07FF * [0])

        # setting pc to RESET handler at 0xFFFC
        self.pc = self.bus.read_double(0xFFFC)

    def step(self):
        log.debug("-" * 60)
        instruction = self.__read_word()
        log.debug("instruction: 0x%02X", instruction)

        address = self.opcodes[instruction]()
        log.debug("-" * 60)
        print_status(self, address)

    def check_flags_nz(self, value):
        self.__check_flag_negative(value)
        self.__check_flag_zero(value)

    # memory access with addressing modes
    def read_abs(self):
        addr = self.__read_double()
        return addr, self.bus.read(addr)

    def read_absx(self):
        addr = self.__read_double() + self.x
        return addr, self.bus.read(addr)

    def read_absy(self):
        addr = self.__read_double() + self.y
        return addr, self.bus.read(addr)

    def read_imm(self):
        return self.__read_word()

    def read_indx(self):
        addr = self.__read_word() + self.x
        addr = self.bus.read_double(addr)
        return addr, self.bus.read(addr)

    def read_indy(self):
        addr = self.__read_word()
        addr = self.bus.read_double(addr) + self.y
        return addr, self.bus.read(addr)

    def read_zp(self):
        addr = self.__read_word()
        return addr, self.bus.read(addr)

    def read_zpx(self):
        addr = self.__read_word() + self.x
        return addr, self.bus.read(addr)

    def read_zpy(self):
        addr = self.__read_word() + self.y
        return addr, self.bus.read(addr)

    def write_abs(self, value):
        addr = self.__read_double()
        self.bus.write(addr, value)
        return addr

    def write_absx(self, value):
        addr = self.__read_double() + self.x
        self.bus.write(addr, value)
        return addr

    def write_absy(self, value):
        addr = self.__read_double() + self.y
        self.bus.write(addr, value)
        return addr

    def write_indx(self, value):
        addr = self.__read_word() + self.x
        addr = self.bus.read_double(addr)
        self.bus.write(addr, value)
        return addr

    def write_indy(self, value):
        addr = self.__read_word()
        addr = self.bus.read_double(addr) + self.y
        self.bus.write(addr, value)
        return addr

    def write_zp(self, value):
        addr = self.__read_word()
        self.bus.write(addr, value)
        return addr

    def write_zpx(self, value):
        addr = self.__read_word() + self.x
        self.bus.write(addr, value)
        return addr

    def write_zpy(self, value):
        addr = self.__read_word() + self.y
        self.bus.write(addr, value)
        return addr

    # instructions
    def adc(self, value):
        carry = self.status & 0b00000001
        before = self.a
        self.a = value + self.a + carry
        self.__check_flag_carry(self.a)
        self.a %= 0x100
        self.__check_flag_overflow_two(self.a, before, value)
        self.check_flags_nz(self.a)

    def _adc_abs(self):
        address, value = self.read_abs()
        self.adc(value)

    def _adc_absx(self):
        address, value = self.read_absx()
        self.adc(value)

    def _adc_imm(self):
        value = self.read_imm()
        self.adc(value)

    def _adc_zp(self):
        # TODO: review test
        address, value = self.read_zp()
        self.adc(value)

    def _adc_zpx(self):
        address, value = self.read_zpx()
        self.adc(value)

    def _adc_absy(self):
        address, value = self.read_absy()
        self.adc(value)

    def _adc_indx(self):
        address, value = self.read_indx()
        self.adc(value)

    def _adc_indy(self):
        address, value = self.read_indy()
        self.adc(value)

    def _and_abs(self):
        address, value = self.read_abs()
        self.a &= value
        self.check_flags_nz(self.a)
        return address

    def _and_absx(self):
        address, value = self.read_absx()
        self.a &= value
        self.check_flags_nz(self.a)
        return address

    def _and_absy(self):
        address, value = self.read_absy()
        self.a &= value
        self.check_flags_nz(self.a)
        return address

    def _and_imm(self):
        value = self.read_imm()
        self.a &= value
        self.check_flags_nz(self.a)

    def _and_indx(self):
        address, value = self.read_indx()
        self.a &= value
        self.check_flags_nz(self.a)
        return address

    def _and_indy(self):
        address, value = self.read_indy()
        self.a &= value
        self.check_flags_nz(self.a)
        return address

    def _and_zp(self):
        address, value = self.read_zp()
        self.a &= value
        self.check_flags_nz(self.a)
        return address

    def _and_zpx(self):
        address, value = self.read_zpx()
        self.a &= value
        self.check_flags_nz(self.a)
        return address

    def __asl (self,value):
        carry = (value & 0b10000000) >> 7
        value = (value << 1) & 0b11111111
        self.status = (self.status & 0b11111110) | carry
        self.check_flags_nz(value)
        return value

    def _asl_abs(self):
        address, value = self.read_abs()
        value = self.__asl(value)
        self.bus.write (address, value)
        return address

    def _asl_absx(self):
        address, value = self.read_absx()
        value = self.__asl(value)
        self.bus.write (address, value)
        return address

    def _asl_acc(self):
        self.a = self.__asl(self.a)

    def _asl_zp(self):
        address, value = self.read_zp()
        value = self.__asl(value)
        self.bus.write (address, value)
        return address

    def _asl_zpx(self):
        address, value = self.read_zpx()
        value = self.__asl(value)
        self.bus.write (address, value)
        return address

    def _bcc(self):
        value = self.read_imm()
        value = two_complements(value)

        if not (self.status & 0b00000001):
            self.pc += value

    def _bcs(self):
        value = self.read_imm()
        value = two_complements(value)

        if self.status & 0b00000001:
            self.pc += value

    def _beq(self):
        value = self.read_imm()
        value = two_complements(value)

        if self.status & 0b00000010:
            self.pc += value

    def __bit(self, value):
        if not self.a & value:
            self.status |= 0b00000010
        else:
            self.status &= 0b11111101

        self.status = (self.status & 0b00111111) | (value & 0b11000000)

    def _bit_abs(self):
        address, value = self.read_abs()
        self.__bit(value)
        return address

    def _bit_zp(self):
        address, value = self.read_zp()
        self.__bit(value)
        return address

    def _bmi(self):
        value = self.read_imm()
        value = two_complements(value)

        if self.status & 0b10000000:
            self.pc += value

    def _bne(self):
        value = self.read_imm()
        value = two_complements(value)

        if not (self.status & 0b00000010):
            self.pc += value

    def _bpl(self):
        value = self.read_imm()
        value = two_complements(value)

        if not (self.status & 0b10000000):
            self.pc += value

    def _brk(self):
        # NOTE: https://wiki.nesdev.com/w/index.php/Status_flags#The_B_flag
        self.__stack_push(self.status | 0b00110000)
        self.__flag_interrupt_set()
        # TODO: needs better way to signal interruption
        raise Exception("brk")

    def _bvc(self):
        value = self.read_imm()
        value = two_complements(value)

        if not (self.status & 0b01000000):
            self.pc += value

    def _bvs(self):
        value = self.read_imm()
        value = two_complements(value)

        if self.status & 0b01000000:
            self.pc += value

    def _clc(self):
        self.status &= 0b11111110

    def _cld(self):
        self.status &= 0b11110111

    def _cli(self):
        self.status &= 0b11111011

    def _clv(self):
        self.status &= 0b10111111

    def __cmp(self, x, y):
        aux = x - y
        if x > y:
            self.status |= 0b00000001
        else:
            self.status &= 0b11111110
        self.check_flags_nz(aux)

    def _cmp_abs(self):
        address, value = self.read_abs()
        self.__cmp(self.a, value)
        return address

    def _cmp_absx(self):
        address, value = self.read_absx()
        self.__cmp(self.a, value)
        return address

    def _cmp_absy(self):
        address, value = self.read_absy()
        self.__cmp(self.a, value)
        return address

    def _cmp_imm(self):
        value = self.read_imm()
        self.__cmp(self.a, value)

    def _cmp_indx(self):
        address, value = self.read_indx()
        self.__cmp(self.a, value)
        return address

    def _cmp_indy(self):
        address, value = self.read_indy()
        self.__cmp(self.a, value)
        return address

    def _cmp_zp(self):
        address, value = self.read_zp()
        self.__cmp(self.a, value)
        return address

    def _cmp_zpx(self):
        address, value = self.read_zpx()
        self.__cmp(self.a, value)
        return address

    def _cpx_abs(self):
        address, value = self.read_abs()
        self.__cmp(self.x, value)
        return address

    def _cpx_imm(self):
        value = self.read_imm()
        self.__cmp(self.x, value)

    def _cpx_zp(self):
        address, value = self.read_zp()
        self.__cmp(self.x, value)
        return address

    def _cpy_abs(self):
        address, value = self.read_abs()
        self.__cmp(self.y, value)
        return address

    def _cpy_imm(self):
        value = self.read_imm()
        self.__cmp(self.y, value)

    def _cpy_zp(self):
        address, value = self.read_zp()
        self.__cmp(self.y, value)
        return address

    def _dec_abs(self):
        address, value = self.read_abs()
        value = dec(value)
        address = self.bus.write(address, value)
        self.check_flags_nz(value)
        return address

    def _dec_absx(self):
        address, value = self.read_absx()
        value = dec(value)
        address = self.bus.write(address, value)
        self.check_flags_nz(value)
        return address

    def _dec_zp(self):
        address, value = self.read_zp()
        value = dec(value)
        address = self.bus.write(address, value)
        self.check_flags_nz(value)
        return address

    def _dec_zpx(self):
        address, value = self.read_zpx()
        value = dec(value)
        address = self.bus.write(address, value)
        self.check_flags_nz(value)
        return address

    def _dex(self):
        self.x = dec(self.x)
        self.check_flags_nz(self.x)

    def _dey(self):
        self.y = dec(self.y)
        self.check_flags_nz(self.y)

    def _eor_abs(self):
        address, value = self.read_abs()
        self.a ^= value
        self.check_flags_nz(self.a)
        return address

    def _eor_absx(self):
        address, value = self.read_absx()
        self.a ^= value
        self.check_flags_nz(self.a)
        return address

    def _eor_absy(self):
        address, value = self.read_absy()
        self.a ^= value
        self.check_flags_nz(self.a)
        return address

    def _eor_imm(self):
        value = self.read_imm()
        self.a ^= value
        self.check_flags_nz(self.a)

    def _eor_indx(self):
        address, value = self.read_indx()
        self.a ^= value
        self.check_flags_nz(self.a)
        return address

    def _eor_indy(self):
        address, value = self.read_indy()
        self.a ^= value
        self.check_flags_nz(self.a)
        return address

    def _eor_zp(self):
        address, value = self.read_zp()
        self.a ^= value
        self.check_flags_nz(self.a)
        return address

    def _eor_zpx(self):
        address, value = self.read_zpx()
        self.a ^= value
        self.check_flags_nz(self.a)
        return address

    def _inc_abs(self):
        address, value = self.read_abs()
        value = inc(value)
        address = self.bus.write(address, value)
        self.check_flags_nz(value)
        return address

    def _inc_absx(self):
        address, value = self.read_absx()
        value = inc(value)
        address = self.bus.write(address, value)
        self.check_flags_nz(value)
        return address

    def _inc_zp(self):
        address, value = self.read_zp()
        value = inc(value)
        address = self.bus.write(address, value)
        self.check_flags_nz(value)
        return address

    def _inc_zpx(self):
        address, value = self.read_zpx()
        value = inc(value)
        address = self.bus.write(address, value)
        self.check_flags_nz(value)
        return address

    def _inx(self):
        self.x = inc(self.x)
        self.check_flags_nz(self.x)

    def _iny(self):
        self.y = inc(self.y)
        self.check_flags_nz(self.y)

    def _jmp_abs(self):
        self.pc = self.__read_double()

    def _jmp_ind(self):
        address = self.__read_double()
        value = self.bus.read_double(address)
        self.pc = value

    def _jsr(self):
        address = self.__read_double()
        value = self.pc
        self.__stack_push((value & 0xFF00) >> 8)
        self.__stack_push(value & 0xFF)
        self.pc = address

    def _lda_abs(self):
        address, self.a = self.read_abs()
        self.check_flags_nz(self.a)
        return address

    def _lda_absx(self):
        address, self.a = self.read_absx()
        self.check_flags_nz(self.a)
        return address

    def _lda_absy(self):
        address, self.a = self.read_absy()
        self.check_flags_nz(self.a)
        return address

    def _lda_imm(self):
        self.a = self.read_imm()
        log_value(self.a)
        self.check_flags_nz(self.a)

    def _lda_indx(self):
        address, self.a = self.read_indx()
        self.check_flags_nz(self.a)
        return address

    def _lda_indy(self):
        address, self.a = self.read_indy()
        self.check_flags_nz(self.a)
        return address

    def _lda_zp(self):
        address, self.a = self.read_zp()
        self.check_flags_nz(self.a)
        return address

    def _lda_zpx(self):
        address, self.a = self.read_zpx()
        self.check_flags_nz(self.a)
        return address

    def _ldx_abs(self):
        address, self.x = self.read_abs()
        self.check_flags_nz(self.x)
        return address

    def _ldx_absy(self):
        address, self.x = self.read_absy()
        self.check_flags_nz(self.x)
        return address

    def _ldx_imm(self):
        self.x = self.read_imm()
        self.check_flags_nz(self.x)

    def _ldx_zp(self):
        address, self.x = self.read_zp()
        self.check_flags_nz(self.x)
        return address

    def _ldx_zpy(self):
        address, self.x = self.read_zpy()
        self.check_flags_nz(self.x)
        return address

    def _ldy_abs(self):
        address, self.y = self.read_abs()
        self.check_flags_nz(self.y)
        return address

    def _ldy_absx(self):
        address, self.y = self.read_absx()
        self.check_flags_nz(self.y)
        return address

    def _ldy_imm(self):
        self.y = self.read_imm()
        self.check_flags_nz(self.y)

    def _ldy_zp(self):
        address, self.y = self.read_zp()
        self.check_flags_nz(self.y)
        return address

    def _ldy_zpx(self):
        address, self.y = self.read_zpx()
        self.check_flags_nz(self.y)
        return address

    def __lsr(self, value):
        carry  = value & 0b0000001
        value  = (value >> 1) & 0b01111111
        self.status = (self.status & 0b11111110) | carry
        self.check_flags_nz(value)
        return value

    def _lsr_abs(self):
         address, value = self.read_abs()
         value = self.__lsr(value)
         self.bus.write(address, value)
         return address

    def _lsr_absx(self):
        address, value = self.read_absx()
        value = self.__lsr(value)
        self.bus.write (address, value)
        return address

    def _lsr_acc(self):
        self.a = self.__lsr(self.a)

    def _lsr_zp(self):
        address, aux = self.read_zp()
        aux = self.__lsr(aux)
        address = self.bus.write(address, aux)
        return address

    def _lsr_zpx(self):
        address, aux = self.read_zpx()
        aux = self.__lsr(aux)
        address = self.bus.write(address, aux)
        return address

    def _nop(self):
        pass

    def _ora_abs(self):
        address, value = self.read_abs()
        self.a |= value
        self.check_flags_nz(self.a)
        return address

    def _ora_absx(self):
        address, value = self.read_absx()
        self.a |= value
        self.check_flags_nz(self.a)
        return address

    def _ora_absy(self):
        address, value = self.read_absy()
        self.a |= value
        self.check_flags_nz(self.a)
        return address

    def _ora_imm(self):
        value = self.read_imm()
        self.a |= value
        self.check_flags_nz(self.a)

    def _ora_indx(self):
        address, value = self.read_indx()
        self.a |= value
        self.check_flags_nz(self.a)
        return address

    def _ora_indy(self):
        address, value = self.read_indy()
        self.a |= value
        self.check_flags_nz(self.a)
        return address

    def _ora_zp(self):
        address, value = self.read_zp()
        self.a = self.a | value
        self.check_flags_nz(self.a)
        return address

    def _ora_zpx(self):
        address, value = self.read_zpx()
        self.a |= value
        self.check_flags_nz(self.a)
        return address

    def _pha(self):
        return self.__stack_push(self.a)

    def _php(self):
        # NOTE: https://wiki.nesdev.com/w/index.php/Status_flags#The_B_flag
        return self.__stack_push(self.status | 0b00110000)

    def _pla(self):
        address, self.a = self.__stack_pull()
        self.check_flags_nz(self.a)
        return address

    def _plp(self):
        address, self.status = self.__stack_pull()
        return address

    def __rol(self, value):
        carry = (value & 0b10000000) >> 7
        value = ((value << 1) & 0b11111110) | (self.status & 0b00000001) & 0xFF
        self.status = (self.status & 0b11111110) | carry
        self.check_flags_nz(value)
        return value

    def _rol_abs(self):
        address, value = self.read_abs()
        value = self.__rol(value)
        self.bus.write(address, value)
        return address

    def _rol_absx(self):
        address, value = self.read_absx()
        value = self.__rol(value)
        self.bus.write(address, value)
        return address

    def _rol_acc(self):
        self.a = self.__rol(self.a)

    def _rol_zp(self):
        address, value = self.read_zp()
        value = self.__rol(value)
        self.bus.write(address, value)
        return address

    def _rol_zpx(self):
        address, value = self.read_zpx()
        value = self.__rol(value)
        self.bus.write(address, value)
        return address

    def __ror(self, value):
        carry = value & 0b00000001
        value = (value >> 1) | ((self.status & 0b00000001) << 7)
        self.status = (self.status & 0b11111110) | carry
        self.check_flags_nz(value)
        return value

    def _ror_abs(self):
        address, value = self.read_abs()
        value = self.__ror(value)
        self.bus.write(address, value)
        return address

    def _ror_absx(self):
        address, value = self.read_absx()
        value = self.__ror(value)
        self.bus.write(address, value)
        return address

    def _ror_acc(self):
        self.a = self.__ror(self.a)

    def _ror_zp(self):
        address, value = self.read_zp()
        value = self.__ror(value)
        self.bus.write(address, value)
        return address

    def _ror_zpx(self):
        address, value = self.read_zpx()
        value = self.__ror(value)
        self.bus.write(address, value)
        return address

    def _rti(self):
        _, self.status = self.__stack_pull()
        self.__stack_pull_pc()

    def _rts(self):
        self.__stack_pull_pc()

    def _sbc_abs(self):
        address, value = self.read_abs()
        self.adc(~value)

    def _sbc_absx(self):
        address, value = self.read_absx()
        self.adc(~value)

    def _sbc_imm(self):
        value = self.read_imm()
        self.adc(~value)

    def _sbc_zp(self):
        address, value = self.read_zp()
        self.adc(~value)

    def _sbc_zpx(self):
        address, value = self.read_zpx()
        self.adc(~value)

    def _sbc_absy(self):
        address, value = self.read_absy()
        self.adc(~value)

    def _sbc_indx(self):
        address, value = self.read_indx()
        self.adc(~value)

    def _sbc_indy(self):
        address, value = self.read_indy()
        self.adc(~value)

    def _sec(self):
        self.status |= 0b00000001

    def _sed(self):
        self.status |= 0b00001000

    def _sei(self):
        self.status |= 0b00000100

    def _sta_abs(self):
        return self.write_abs(self.a)

    def _sta_absx(self):
        return self.write_absx(self.a)

    def _sta_absy(self):
        return self.write_absy(self.a)

    def _sta_indx(self):
        return self.write_indx(self.a)

    def _sta_indy(self):
        return self.write_indy(self.a)

    def _sta_zp(self):
        return self.write_zp(self.a)

    def _sta_zpx(self):
        return self.write_zpx(self.a)

    def _stx_abs(self):
        return self.write_abs(self.x)

    def _stx_zp(self):
        return self.write_zp(self.x)

    def _stx_zpy(self):
        return self.write_zpy(self.x)

    def _sty_abs(self):
        return self.write_abs(self.y)

    def _sty_zp(self):
        return self.write_zp(self.y)

    def _sty_zpx(self):
        return self.write_zpx(self.y)

    def _tax(self):
        self.x = self.a
        self.check_flags_nz(self.x)

    def _tay(self):
        self.y = self.a
        self.check_flags_nz(self.y)

    def _tsx(self):
        self.x = self.sp & 0xFF
        self.check_flags_nz(self.x)

    def _txa(self):
        self.a = self.x
        self.check_flags_nz(self.a)

    def _txs(self):
        self.sp = 0x0100 | self.x
        # NOTE: do not check flags

    def _tya(self):
        self.a = self.y
        self.check_flags_nz(self.a)

    # private stuff

    def __read_word(self):
        value = self.bus.read(self.pc)
        self.__pc_increase()
        return value

    def __read_double(self):
        value = self.bus.read_double(self.pc)
        self.__pc_increase()
        self.__pc_increase()
        return value

    def __pc_increase(self):
        self.pc = inc(self.pc, 16)

    def __check_flag_zero(self, value):
        if value == 0:
            self.status |= 0b00000010
        else:
            self.status &= 0b11111101

    def __check_flag_negative(self, value):
        if value & 0b10000000:
            self.status |= 0b10000000
        else:
            self.status &= 0b01111111

    def __check_flag_carry(self, value):
        if value > 255 or value < 0:
            self.status |= 0b00000001
        else:
            self.status &= 0b11111110

    def __check_flag_overflow_two(self, value, parc1, parc2):
        mask = 0b10000000
        overflow_res = value & mask
        overflow_parc1 = parc1 & mask
        overflow_parc2 = parc2 & mask
        if (overflow_parc1 == overflow_parc2) and (overflow_parc1 != overflow_res):
            self.status |= 0b01000000
        else:
            self.status &= 0b10111111

    def __flag_interrupt_set(self):
        self.status |= 0b00000100

    def __stack_push(self, value):
        address = self.sp
        address = self.bus.write(address, value)
        self.sp -= 1
        return address

    def __stack_pull(self):
        self.sp += 1
        address = self.sp
        value = self.bus.read(address)
        return address, value

    def __stack_pull_pc(self):
        _, low = self.__stack_pull()
        _, high = self.__stack_pull()
        self.pc = (high << 8) + low
