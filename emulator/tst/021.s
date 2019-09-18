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
  LDX #$00
  LDX #$42
  LDX #$7F
  LDX #$80
  LDX #$FF

  LDX #-1
  LDX #-16
  LDX #-128
  LDX #127
  LDX #64
  LDX #32
  LDX #16
  LDX #8
  LDX #4
  LDX #2
  LDX #0

  LDX #%11111111
  LDX #%10101010
  LDX #%10000000
  LDX #%01111111
  LDX #%01010101
  LDX #%00000000
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
