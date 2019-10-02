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
  LDA #$42
  STA $01
  STA $0401
  LDA #$A0
  STA $02
  STA $0402

  LDA #$00
  ORA #$00
  ORA #$42
  ORA #$A0

  LDA #$42
  ORA $00
  LDA #$42
  ORA $01
  LDA #$42
  ORA $02

  LDA #$A0
  ORA $00
  LDA #$A0
  ORA $01
  LDA #$A0
  ORA $02

  LDX #$00
  LDY #$00
  LDA #$42
  ORA $00,X
  LDA #$42
  ORA $01,X
  LDA #$42
  ORA $02,X
  LDA #$42
  ORA $0400
  LDA #$42
  ORA $0401
  LDA #$42
  ORA $0402
  LDA #$42
  ORA $0400,X
  LDA #$42
  ORA $0401,X
  LDA #$42
  ORA $0402,X
  LDA #$42
  ORA $0400,Y
  LDA #$42
  ORA $0401,Y
  LDA #$42
  ORA $0402,Y

  LDA #$42
  ORA ($10,X)
  LDA #$42
  ORA ($10),Y
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
