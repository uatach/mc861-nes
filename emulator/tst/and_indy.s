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
  LDA #$44 ;test AND
  STA $a001
  LDX #$00
  STX $17
  LDX #$a0
  STX $18
  LDY #$1
  AND ($17), Y
  CLC
  LDY #$0
  STY $a002
  LDX #$01
  STX $17
  LDX #$a0
  STX $18
  LDY #$1
  AND ($17), Y ;test flag zero
  CLC
  LDA #$80 ; test flag negative
  STA $a003
  LDX #$02
  STX $17
  LDX #$a0
  STX $18
  LDX #$1
  AND ($17), Y
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
