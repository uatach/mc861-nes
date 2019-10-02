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
  LDA #$A0
  STA $00
  STA $0400
  LDA #$42
  STA $01
  STA $0401

  CMP #$00
  CMP #$42
  CMP #$A0
  CMP $02
  CMP $01
  CMP $00
  CMP $0402
  CMP $0401
  CMP $0400

  LDX #$00
  LDY #$00
  CMP $02,X
  CMP $01,X
  CMP $00,X
  CMP $0402,X
  CMP $0401,X
  CMP $0400,X
  CMP $0402,Y
  CMP $0401,Y
  CMP $0400,Y

  CMP ($10,X)
  CMP ($10),Y
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
