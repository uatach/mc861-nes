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
  LDY #$16
  STY $00
  STY $FF

  LDY #$42
  STY $0000
  STY $0001
  STY $00FF
  STY $0136
  STY $0748
  STY $0A62
  STY $10A5
  STY $39F0
  STY $6001
  STY $9119
  STY $AAAA
  STY $C123
  STY $E987
  STY $FFFE
  STY $FFFF

  LDY $10
  LDY $00
  LDY $10
  LDY $FF
  LDY $10
  LDY $0136
  LDY $10
  LDY $39F0
  LDY $10
  LDY $E987

  LDA #$10
  LDX #$02
  LDY #$10
  STY $10,X
  STY $11,X
  STA $0200,X
  STA $0300,X

  LDY #$42
  LDY $10,X
  LDY #$42
  LDY $11,X
  LDY #$42
  LDY $0200,X
  LDY #$42
  LDY $0300,X
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
