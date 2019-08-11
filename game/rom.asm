
;---------------------------------------------------------------
; memory sections / sizes
; $0000-07FF -  2KB - Internal RAM, chip in the NES
; $0800-1FFF -  6KB - RAM Mirrors
; $2000-2007 -  1B  - PPU access ports
; $3F00-3F0F -  2B  - PPU background palette
; $3F10-3F1F -  2B  - PPU sprites palette
; $4000-4017 -  3B  - APU and controller access ports
; $6000-7FFF -  8KB - Optional WRAM inside the game cart
; $8000-FFFF - 32KB - Game cart ROM
;----------------------------------------------------------------

;----------------------------------------------------------------
; constants
;----------------------------------------------------------------

;number of PRG pages
PRG_COUNT = 1 ;1 = 16KB, 2 = 32KB

;number of CHR pages
CHR_COUNT = 1 ;1 = 8KB, 2 = 16KB

;TODO: explain
;%0000 = horizontal, %0001 = vertical, %1000 = four-screen
MIRRORING = %0001

;----------------------------------------------------------------
; variables
;----------------------------------------------------------------

  .enum $0000

  ;NOTE: declare variables using the DSB and DSW directives, like this:

  ;MyVariable0 .dsb 1
  ;MyVariable1 .dsb 3

  .ende

  ;NOTE: you can also split the variable declarations into individual pages, like this:

  ;.enum $0100
  ;.ende

  ;.enum $0200
  ;.ende

;----------------------------------------------------------------
; iNES header
;----------------------------------------------------------------

  .db "NES", $1a ;identification of the iNES header
  .db PRG_COUNT ;number of 16KB PRG-ROM pages
  .db CHR_COUNT ;number of 8KB CHR-ROM pages
  .db $00|MIRRORING ;mapper 0 and mirroring
  .dsb 9, $00 ;clear the remaining bytes

;----------------------------------------------------------------
; program bank(s)
;----------------------------------------------------------------

  .base $10000-(PRG_COUNT*$4000) ; aka $8000 or $C000

LoadPalettes:
  LDX #$00
LoadPalettesLoop:
  LDA PaletteData,X
  STA $2007
  INX
  CPX #$20
  BNE LoadPalettesLoop
  RTS

loop:
  JMP loop

;----------------------------------------------------------------
; interrupt handlers
;----------------------------------------------------------------

RESET:
  ;NOTE: initialization code goes here
  LDA #%00100000 ; intensify background
  STA $2001
  JSR LoadPalettes
  JMP loop

NMI:
  ;NOTE: NMI code goes here
  RTI

IRQ:
  ;NOTE: IRQ code goes here
  RTI

;----------------------------------------------------------------
; data
;----------------------------------------------------------------

; palettes from tutorial
PaletteData:
  ;background palette data
  .db $0F,$31,$32,$33,$0F,$35,$36,$37,$0F,$39,$3A,$3B,$0F,$3D,$3E,$0F
  ;sprite palette data
  .db $0F,$1C,$15,$14,$0F,$02,$38,$3C,$0F,$1C,$15,$14,$0F,$02,$38,$3C

;----------------------------------------------------------------
; interrupt vectors
;----------------------------------------------------------------

  .org $FFFA
  .dw NMI
  .dw RESET
  .dw IRQ

;----------------------------------------------------------------
; CHR-ROM bank
;----------------------------------------------------------------

  .incbin "tiles.chr"
