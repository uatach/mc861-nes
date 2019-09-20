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
  LDX #$16
  STX $00
  STX $FF

  LDX #$42
  STX $0000
  STX $0001
  STX $00FF
  STX $0136
  STX $0748
  STX $0A62
  STX $10A5
  STX $39F0
  STX $6001
  STX $9119
  STX $AAAA
  STX $C123
  STX $E987
  STX $FFFE
  STX $FFFF

  LDX $10
  LDX $00
  LDX $10
  LDX $FF
  LDX $10
  LDX $0136
  LDX $10
  LDX $39F0
  LDX $10
  LDX $E987

  LDA #$10
  LDX #$10
  LDY #$02
  STX $10,Y
  STX $11,Y
  STA $0200,Y
  STA $0300,Y

  LDX #$42
  LDX $10,Y
  LDX #$42
  LDX $11,Y
  LDX #$42
  LDX $0200,Y
  LDX #$42
  LDX $0300,Y
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
