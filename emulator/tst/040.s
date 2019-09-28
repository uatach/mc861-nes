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
  LDA #%00000001
  BIT $00
  STA $00
  BIT $00
  BIT $0200
  STA $0200
  BIT $0200
  BIT $0200

  LDA #%01000010
  BIT $10
  STA $10
  BIT $10
  CLV
  CLV
  BIT $10
  BIT $0210
  STA $0210
  BIT $0210
  BIT $0210
  CLV

  LDA #%10001000
  BIT $20
  STA $20
  BIT $20
  BIT $0220
  STA $0220
  BIT $0220
  BIT $0220

  LDA #$00
  BIT $00
  BIT $10
  BIT $20
  BIT $0200
  BIT $0210
  BIT $0220
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
