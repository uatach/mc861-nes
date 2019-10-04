;----------------------------------------------------------------
; constants
;----------------------------------------------------------------
PRG_COUNT = 1 ;1 = 16KB, 2 = 32KB
MIRRORING = %0001 ;%0000 = horizontal, %0001 = vertical, %1000 = four-screen

;----------------------------------------------------------------
; variables
;----------------------------------------------------------------

  .enum $0000
  .ende

;----------------------------------------------------------------
; iNES header
;----------------------------------------------------------------

  .db "NES", $1a ;identification of the iNES header
  .db PRG_COUNT ;number of 16KB PRG-ROM pages
  .db $01 ;number of 8KB CHR-ROM pages
  .db $00|MIRRORING ;mapper 0 and mirroring
  .dsb 9, $00 ;clear the remaining bytes

;----------------------------------------------------------------
; program bank(s)
;----------------------------------------------------------------

  .base $10000-(PRG_COUNT*$4000)

RESET:
  JMP test
test:
 CLC
<<<<<<< HEAD
  ADC #$8   ;pair without

=======
 LDA #$08  ;pair without
 
>>>>>>> 61524d9c709a3e7edea21d4f7f2a0b151213391a
  LSR
  LSR
  LSR
  LSR
  LSR
  LSR
  LSR
  CLC
  ADC #$8
  ASL
  ASL
  ASL
  ASL
  ASL
  ASL
  ASL
  ASL

  ADC #$8
  ROR
  ROR
  ROR
  ROR
  ROR
  ROR
  ROR
  ROR
  ROR
  ADC #$8
  ROL
  ROL
  ROL
  ROL
  ROL
  ROL
  ROL
  ROL
  ROL
  ROL



<<<<<<< HEAD


=======
>>>>>>> 61524d9c709a3e7edea21d4f7f2a0b151213391a

  BRK ; Abort execution


NMI:
  ;NOTE: NMI code goes here

IRQ:
  ;NOTE: IRQ code goes here

;----------------------------------------------------------------
; interrupt vectors
;----------------------------------------------------------------

  .org $FFFA
  .dw NMI
  .dw RESET
  .dw IRQ
