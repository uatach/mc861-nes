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
  LDA #$16
  STA $00
  STA $FF

  LDA #$42
  STA $0000
  STA $0001
  STA $00FF
  STA $0136
  STA $0748
  STA $0A62
  STA $10A5
  STA $39F0
  STA $6001
  STA $9119
  STA $AAAA
  STA $C123
  STA $E987
  STA $FFFE
  STA $FFFF

  LDA $10
  LDA $00
  LDA $10
  LDA $FF
  LDA $10
  LDA $0136
  LDA $10
  LDA $39F0
  LDA $10
  LDA $E987

  LDX #$01
  LDY #$02
  LDA #$10
  STA $10,X
  STA $11,X
  STA $0200,X
  STA $0300,Y
  STA ($01,X)
  STA ($11),Y

  LDA #$42
  LDA $02
  LDA #$42
  LDA $10,X
  LDA #$42
  LDA $11,X
  LDA #$42
  LDA $0200,X
  LDA #$42
  LDA $0300,Y
  LDA #$42
  LDA ($01,X)
  LDA #$42
  LDA ($11),Y
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
