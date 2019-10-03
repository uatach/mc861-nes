;----------------------------------------------------------------
; constants
;----------------------------------------------------------------
PRG_COUNT = 1 ;1 = 16KB, 2 = 32KB
<<<<<<< HEAD
MIRRORING = %0001 ;%0000 = horizontal, %0001 = vertical, %1000 = four-screen
=======
MIRRORING = %0001 ;%0000 = horizontal, %0001 = vertical, %0100 = four-screen
>>>>>>> 61524d9c709a3e7edea21d4f7f2a0b151213391a

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
<<<<<<< HEAD
=======
 CLC

 LDA #$20
 STA $010F
 LDA #$0000

 LDX #$0F
 LSR $0100, X
 LSR $0100, X
 LSR $0100, X
 LSR $0100, X
 LSR $0100, X
 LSR $0100, X
 LSR $0100, X
 
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
