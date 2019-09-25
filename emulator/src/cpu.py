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
    memory = attr.ib(None)

    def __attrs_post_init__(self):
        # setting class properties
        for reg in ["pc", "a", "x", "y", "sp", "status"]:
            setattr(CPU, reg, Register())

        self.opcodes = {
            0x00: self._brk,
            # 0x01: self._ora_indx,
            # 0x05: self._ora_zp,
            0x06: self._asl_zp,
            0x08: self._php,
            # 0x09: self._ora_imm,
            0x0A: self._asl_acc,
            # 0x0D: self._ora_abs,
            0x0E: self._asl_abs,
            0x10: self._bpl,
            # 0x11: self._ora_indy,
            # 0x15: self._ora_zpx,
            0x16: self._asl_zpx,
            0x18: self._clc,
            # 0x19: self._ora_absy,
            # 0x1D: self._ora_absx,
            0x1E: self._asl_absx,
            0x20: self._jsr,
            # 0x21: self._and_indx,
            0x24: self._bit_zp,
            # 0x25: self._and_zp,
            # 0x26: self._rol_zp,
            0x28: self._plp,
            0x29: self._and_imm,
            # 0x2A: self._rol_acc,
            0x2C: self._bit_abs,
            # 0x2D: self._and_abs,
            # 0x2E: self._rol_abs,
            # 0x30: self._bmi,
            # 0x31: self._and_indy,
            # 0x35: self._and_zpx,
            # 0x36: self._rol_zpx,
            0x38: self._sec,
            # 0x39: self._and_absy,
            # 0x3D: self._and_absx,
            # 0x3E: self._rol_absx,
            0x40: self._rti,
            0x46: self._lsr_zp,
            0x48: self._pha,
            0x4A: self._lsr_acc,
            0x4C: self._jmp_abs,
            0x4E: self._lsr_abs,
            0x56: self._lsr_zpx,
            0x58: self._cli,
            0x5E: self._lsr_absx,
            0x60: self._rts,
            0x61: self._adc_indx,
            0x65: self._adc_zp,
            0x68: self._pla,
            0x69: self._adc_imm,
            0x6C: self._jmp_ind,
            0x6D: self._adc_abs,
            0x71: self._adc_indy,
            0x75: self._adc_zpx,
            0x78: self._sei,
            0x79: self._adc_zpy,
            0x7D: self._adc_absx,
            0x81: self._sta_indx,
            0x84: self._sty_zp,
            0x85: self._sta_zp,
            0x86: self._stx_zp,
            0x8A: self._txa,
            0x8C: self._sty_abs,
            0x8D: self._sta_abs,
            0x8E: self._stx_abs,
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
            0xC8: self._iny,
            0xD8: self._cld,
            0xE6: self._inc_zp,
            0xE8: self._inx,
            0xEA: self._nop,
            0xEE: self._inc_abs,
            0xF6: self._inc_zpx,
            0xF8: self._sed,
            0xFE: self._inc_absx,
        }
        log.info("Handling %d opcodes", len(self.opcodes))

    def setup(self, rom):
        assert len(self.memory) > len(rom)

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
        log.debug("-" * 60)
        instruction = self.__read_word()
        log.debug("instruction: 0x%02X", instruction)

        address = self.opcodes[instruction]()
        log.debug("-" * 60)
        print_status(self, address)

    # instructions

    def _adc_abs(self):
        before = self.a
        address = self.__read_double()
        self.a = self.memory[address] + self.a
        self.__check_flag_carry(self.a)
        self.__check_flag_overflow(self.a, before)
        self.__check_flag_zero(self.a)
        self.__check_flag_negative(self.a)

    def _adc_absx(self):
        before = self.a
        address = self.__read_double()
        self.a = self.memory[address] + self.a
        self.__check_flag_carry(self.a)
        self.__check_flag_overflow(self.a, before)
        self.__check_flag_zero(self.a)
        self.__check_flag_negative(self.a)

    def _adc_imm(self):
        before = self.a
        self.a = self.__read_word() + self.a
        self.__check_flag_carry(self.a)
        self.__check_flag_overflow(self.a, before)
        self.__check_flag_zero(self.a)
        self.__check_flag_negative(self.a)

    def _adc_zp(self):
        # TODO: review test
        before = self.a
        self.a = self.memory[self.__read_word()] + self.a
        self.__check_flag_carry(self.a)
        self.__check_flag_overflow(self.a, before)
        self.__check_flag_zero(self.a)
        self.__check_flag_negative(self.a)

    def _adc_zpx(self):
        before = self.a
        address = self.__read_word() + self.x
        self.a = self.memory[address] + self.a
        self.__check_flag_carry(self.a)
        self.__check_flag_overflow(self.a, before)
        self.__check_flag_zero(self.a)
        self.__check_flag_negative(self.a)

    def _adc_zpy(self):
        before = self.a
        address = self.__read_word() + self.y
        self.a = self.memory[address] + self.a
        self.__check_flag_carry(self.a)
        self.__check_flag_overflow(self.a, before)
        self.__check_flag_zero(self.a)
        self.__check_flag_negative(self.a)

    def _adc_indx(self):
        before = self.a
        value = self.__read_word() + self.x
        address = (self.memory[value + 1] << 8) + self.memory[value]
        self.a = self.memory[address] + self.a
        self.__check_flag_carry(self.a)
        self.__check_flag_overflow(self.a, before)
        self.__check_flag_zero(self.a)
        self.__check_flag_negative(self.a)

    def _adc_indy(self):
        before = self.a
        value = self.__read_word()
        address = (self.memory[value + 1] << 8) + self.memory[value] + self.y
        self.a = self.memory[address] + self.a
        self.__check_flag_carry(self.a)
        self.__check_flag_overflow(self.a, before)
        self.__check_flag_zero(self.a)
        self.__check_flag_negative(self.a)

    def _and_imm(self):
        # TODO: write tests
        self.a = self.__read_word() & self.a
        self.__check_flag_zero(self.a)
        self.__check_flag_negative(self.a)

    def _asl_acc(self):
        # set carry flag
        self.status |= (self.a & 0b10000000) >> 7
        # shift left
        self.a = (self.a << 1) & 0b11111111
        self.__check_flag_zero(self.a)
        self.__check_flag_negative(self.a)


    def __bit(self, address):
        value = self.memory[address]

        if not self.a & value:
            self.status |= 0b00000010
        else:
            self.status &= 0b11111101

        self.status = (self.status & 0b00111111) | (value & 0b11000000)

    def _bit_abs(self):
        address = self.__read_double()
        self.__bit(address)
        return address

    def _bit_zp(self):
        address = self.__read_word()
        self.__bit(address)
        return address

    def _bpl(self):
        value = self.__read_word()

        # handling negative number
        if value & 0b10000000:
            value = -1 * ((value ^ 0xFF) + 1)

        if not (self.status & 0b10000000):
            self.pc += value


   
    def _brk(self):
        # set break flag
        self.status |= 0b00010000
        # TODO: needs better way to signal interruption
        raise Exception("brk")

    def _clc(self):
        self.status &= 0b11111110

    def _cld(self):
        self.status &= 0b11110111

    def _cli(self):
        self.status &= 0b11111011

    def _clv(self):
        self.status &= 0b10111111

    def _inc_abs(self):
        address = self.__read_double()
        value = (self.memory[address] + 1) % 2 ** 8
        self.memory[address] = value
        self.__check_flag_zero(value)
        self.__check_flag_negative(value)
        return address

    def _inc_absx(self):
        address = self.__read_double() + self.x
        value = (self.memory[address] + 1) % 2 ** 8
        self.memory[address] = value
        self.__check_flag_zero(value)
        self.__check_flag_negative(value)
        return address

    def _inc_zp(self):
        address = self.__read_word()
        value = (self.memory[address] + 1) % 2 ** 8
        self.memory[address] = value
        self.__check_flag_zero(value)
        self.__check_flag_negative(value)
        return address

    def _inc_zpx(self):
        address = self.__read_word() + self.x
        value = (self.memory[address] + 1) % 2 ** 8
        self.memory[address] = value
        self.__check_flag_zero(value)
        self.__check_flag_negative(value)
        return address

    def _inx(self):
        self.x = (self.x + 1) % 2 ** 8
        self.__check_flag_zero(self.x)
        self.__check_flag_negative(self.x)

    def _iny(self):
        self.y = (self.y + 1) % 2 ** 8
        self.__check_flag_zero(self.y)
        self.__check_flag_negative(self.y)

    def _jmp_abs(self):
        self.pc = self.__read_double()

    def _jmp_ind(self):
        address = self.__read_double()
        value = (self.memory[address + 1] << 8) + self.memory[address]
        self.pc = value

    def _jsr(self):
        address = self.__read_double()
        value = self.pc
        self.__stack_push((value & 0xFF00) >> 8)
        self.__stack_push(value & 0xFF)
        self.pc = address

    def _lda_imm(self):
        self.a = self.__read_word()
        log_value(self.a)
        self.__check_flag_zero(self.a)
        self.__check_flag_negative(self.a)

    def _lda_abs(self):
        address = self.__read_double()
        self.a = self.memory[address]
        self.__check_flag_zero(self.a)
        self.__check_flag_negative(self.a)
        return address

    def _lda_absx(self):
        address = self.__read_double() + self.x
        self.a = self.memory[address]
        self.__check_flag_zero(self.a)
        self.__check_flag_negative(self.a)
        return address

    def _lda_absy(self):
        address = self.__read_double() + self.y
        self.a = self.memory[address]
        self.__check_flag_zero(self.a)
        self.__check_flag_negative(self.a)
        return address

    def _lda_indx(self):
        value = self.__read_word()
        address = self.memory[value] + self.x
        self.a = self.memory[address]
        self.__check_flag_zero(self.a)
        self.__check_flag_negative(self.a)
        return address

    def _lda_indy(self):
        value = self.__read_word()
        address = (self.memory[value + 1] << 8) + self.memory[value] + self.y
        self.a = self.memory[address]
        self.__check_flag_zero(self.a)
        self.__check_flag_negative(self.a)
        return address

    def _lda_zp(self):
        address = self.__read_word()
        self.a = self.memory[address]
        self.__check_flag_zero(self.a)
        self.__check_flag_negative(self.a)
        return address

    def _lda_zpx(self):
        address = self.__read_word() + self.x
        self.a = self.memory[address]
        self.__check_flag_zero(self.a)
        self.__check_flag_negative(self.a)
        return address

    def _ldx_abs(self):
        address = self.__read_double()
        self.x = self.memory[address]
        self.__check_flag_zero(self.x)
        self.__check_flag_negative(self.x)
        return address

    def _ldx_absy(self):
        address = self.__read_double() + self.y
        self.x = self.memory[address]
        self.__check_flag_zero(self.x)
        self.__check_flag_negative(self.x)
        return address

    def _ldx_imm(self):
        self.x = self.__read_word()
        self.__check_flag_zero(self.x)
        self.__check_flag_negative(self.x)

    def _ldx_zp(self):
        address = self.__read_word()
        self.x = self.memory[address]
        self.__check_flag_zero(self.x)
        self.__check_flag_negative(self.x)
        return address

    def _ldx_zpy(self):
        address = self.__read_word() + self.y
        self.x = self.memory[address]
        self.__check_flag_zero(self.x)
        self.__check_flag_negative(self.x)
        return address

    def _ldy_abs(self):
        address = self.__read_double()
        self.y = self.memory[address]
        self.__check_flag_zero(self.y)
        self.__check_flag_negative(self.y)
        return address

    def _ldy_absx(self):
        address = self.__read_double() + self.x
        self.y = self.memory[address]
        self.__check_flag_zero(self.y)
        self.__check_flag_negative(self.y)
        return address

    def _ldy_imm(self):
        self.y = self.__read_word()
        self.__check_flag_zero(self.y)
        self.__check_flag_negative(self.y)

    def _ldy_zp(self):
        address = self.__read_word()
        self.y = self.memory[address]
        self.__check_flag_zero(self.y)
        self.__check_flag_negative(self.y)
        return address

    def _ldy_zpx(self):
        address = self.__read_word() + self.x
        self.y = self.memory[address]
        self.__check_flag_zero(self.y)
        self.__check_flag_negative(self.y)
        return address


    def _lsr_abs(self):
        self.status |= (self.__read_word() & 0b0000001) 
        self.a = (self.__read_word()>>1) & 0b01111111

        self.__check_flag_negative(self.a)
        self.__check_flag_zero(self.a)

    def _lsr_absx(self):
        self.status |= (self.__read_double + self.x) & 0b0000001
        self.a = ((self.__read_double + self.x) >> 1) & 0b01111111
        # tem que adicionar o overflow
        self.__check_flag_negative(self.a)
        self.__check_flag_zero(self.a)

    def _lsr_acc(self):
        # set carry flag
        self.status |= (self.a & 0b0000001) 
        # shift left
        self.a = (self.a >> 1) & 0b01111111
        self.__check_flag_zero(self.a)
        self.__check_flag_negative(self.a)


    def _lsr_zp(self):
        
        
        address = self.__read_word()
        aux = self.memory[address] 
        
        # set carry flag
        self.status |= (aux & 0b0000001) 
        # shift left
        self.a = (aux >> 1) & 0b01111111
        
        self.memory[address] = aux

        # tem que adicionar o overflow
        self.__check_flag_negative(self.a)
        self.__check_flag_zero(self.a)

        return address

    def _lsr_zpx(self):
        address = self.__read_word()
        aux = ((self.memory[address] + self.x))        
        # set carry flag
        self.status |= (aux & 0b0000001) 
        # shift left
        self.a = (aux >> 1) & 0b01111111
        
        self.memory[address] = aux

        # tem que adicionar o overflow
        self.__check_flag_negative(self.a)
        self.__check_flag_zero(self.a)

        return address

    def _nop(self):
        pass

    def _pha(self):
        self.__stack_push(self.a)

    def _php(self):
        self.__stack_push(self.status)

    def _pla(self):
        self.a = self.__stack_pull()
        self.__check_flag_zero(self.a)
        self.__check_flag_negative(self.a)

    def _plp(self):
        self.status = self.__stack_pull()

    def _rti(self):
        self.status = self.__stack_pull()
        value = self.__stack_pull()
        value += self.__stack_pull() << 8
        self.pc = value

    def _rts(self):
        value = self.__stack_pull()
        value += self.__stack_pull() << 8
        self.pc = value

    def _sec(self):
        self.status |= 0b00000001

    def _sed(self):
        self.status |= 0b00001000

    def _sei(self):
        # TODO: write tests
        self.status |= 0b00000100

    def _sta_abs(self):
        address = self.__read_double()
        self.memory[address] = self.a
        return address

    def _sta_absx(self):
        address = self.__read_double() + self.x
        self.memory[address] = self.a
        return address

    def _sta_absy(self):
        address = self.__read_double() + self.y
        self.memory[address] = self.a
        return address

    def _sta_indx(self):
        value = self.__read_word()
        address = self.memory[value] + self.x
        self.memory[address] = self.a
        return address

    def _sta_indy(self):
        value = self.__read_word()
        address = (self.memory[value + 1] << 8) + self.memory[value] + self.y
        self.memory[address] = self.a
        return address

    def _sta_zp(self):
        address = self.__read_word()
        self.memory[address] = self.a
        return address

    def _sta_zpx(self):
        address = self.__read_word() + self.x
        self.memory[address] = self.a
        return address

    def _stx_abs(self):
        address = self.__read_double()
        self.memory[address] = self.x
        return address

    def _stx_zp(self):
        address = self.__read_word()
        self.memory[address] = self.x
        return address

    def _stx_zpy(self):
        address = self.__read_word() + self.y
        self.memory[address] = self.x
        return address

    def _sty_abs(self):
        address = self.__read_double()
        self.memory[address] = self.y
        return address

    def _sty_zp(self):
        address = self.__read_word()
        self.memory[address] = self.y
        return address

    def _sty_zpx(self):
        address = self.__read_word() + self.x
        self.memory[address] = self.y
        return address

    def _tax(self):
        self.x = self.a
        self.__check_flag_zero(self.x)
        self.__check_flag_negative(self.x)

    def _tay(self):
        self.y = self.a
        self.__check_flag_zero(self.y)
        self.__check_flag_negative(self.y)

    def _tsx(self):
        self.x = self.sp & 0xFF
        self.__check_flag_zero(self.x)
        self.__check_flag_negative(self.x)

    def _txa(self):
        self.a = self.x
        self.__check_flag_zero(self.a)
        self.__check_flag_negative(self.a)

    def _txs(self):
        self.sp = 0x0100 | self.x

    def _tya(self):
        self.a = self.y
        self.__check_flag_zero(self.a)
        self.__check_flag_negative(self.a)

    # private stuff

    def __read_word(self, address=None):
        address = address or self.pc
        value = self.memory[address]
        self.__pc_increase()
        return value

    def __read_double(self, address=None):
        address = address or self.pc
        value = (self.memory[address + 1] << 8) + self.memory[address]
        self.__pc_increase()
        self.__pc_increase()
        return value

    def __pc_increase(self):
        self.pc = (self.pc + 1) % 2 ** 16

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
        # FIXME: it's doing same check from negative flag
        if value & 0b10000000:
            self.status |= 0b00000001
        else:
            self.status &= 0b11111110

    def __check_flag_overflow(self, value, value_before):
        mask = 0b10000000
        overflow = value & mask
        overflow_before = value_before & mask
        if overflow_before != overflow:
            self.status |= 0b01000000
        else:
            self.status &= 0b10111111

    def __stack_push(self, value):
        self.memory[self.sp] = value
        self.sp -= 1

    def __stack_pull(self):
        self.sp += 1
        value = self.memory[self.sp]
        return value



#**asl **#
#***********************************************#
#Todo: Tests;
#************************************************#



    def _asl_abs(self):
        self.status |= (self.__read_word() & 0b10000000) >> 7
        self.a = (self.__read_word() << 1) & 0b11111111

        self.__check_flag_negative(self.a)
        self.__check_flag_zero(self.a)

    def _asl_absx(self):
        self.status |= ((self.__read_double + self.x ) & 0b10000000) >> 7
        self.a = ((self.__read_double + self.x ) << 1) & 0b11111111

        self.__check_flag_negative(self.a)
        self.__check_flag_zero(self.a)


    def _asl_zp(self):
        
        
        address = self.__read_word()
        aux = self.memory[address] 
        
        
        # set carry flag
        self.status |= ((aux ) & 0b10000000) >> 7 
        # shift left
        self.a = (aux << 1) & 0b11111111
        self.memory[address] = aux

        self.__check_flag_negative(self.a)
        self.__check_flag_zero(self.a)

        return address

    def _asl_zpx(self):
        address = self.__read_word()
        aux = ((self.memory[address] + self.x))        
        # set carry flag
        self.status |= ((aux ) & 0b10000000) >> 7 
        # shift left
        self.a = (aux << 1) & 0b11111111
        
        self.memory[address] = aux

        # tem que adicionar o overflow
        self.__check_flag_negative(self.a)
        self.__check_flag_zero(self.a)

        return address