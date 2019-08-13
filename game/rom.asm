
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

;PPU registers
PPUCTRL = $2000
PPUMASK = $2001
PPUSTATUS = $2002
PPUSCROLL = $2005
PPUADDR = $2006
PPUDATA = $2007

;OAM registers
OAMADDR = $2003
OAMDATA = $2004
OAMDMA = $4014

JOY1 = $4016
JOY2 = $4017

;----------------------------------------------------------------
; variables
;----------------------------------------------------------------

  .enum $0000

  ;NOTE: declare variables using the DSB and DSW directives, like this:

  ;MyVariable0 .dsb 1
  ;MyVariable1 .dsb 3

  sprites .dsb 16
  posx .dsb 1
  posy .dsb 1

  controller1 .dsb 1
  controller2 .dsb 1

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

WaitVBlanck:
  BIT PPUSTATUS
  BPL WaitVBlanck
  RTS

EnableRendering:
  LDA #%10010000
  STA PPUCTRL
  LDA #%00011110
  STA PPUMASK
  LDA #$00
  STA PPUSCROLL
  STA PPUSCROLL
  RTS

RESET:
  ;NOTE: initialization code goes here
  SEI             ; disable IRQs
  CLD             ; disable decimal mode
  LDX #$00
  STX $4015
  LDX #$40
  STX $4017
  LDX #$FF
  TXS             ; set up stack
  INX
  STX PPUCTRL     ; disable NMI
  STX PPUMASK     ; disable rendering
  STX $4010       ; disable DMC
  BIT PPUSTATUS   ; clean up

  JSR WaitVBlanck

  ; X = 0
ClearMemory:      ; setup ram
  LDA #$00
  STA $0000,X
  STA $0100,X
  STA $0300,X
  STA $0400,X
  STA $0500,X
  STA $0600,X
  STA $0700,X
  LDA #$FE
  STA $0200,X
  INX
  BNE ClearMemory

  JSR WaitVBlanck

LoadPalettes:
  LDA PPUSTATUS
  LDA #$00
  STA PPUCTRL
  STA PPUMASK
  LDA #$3F
  STA PPUADDR
  LDA #$00
  STA PPUADDR

  LDX #$00
LoadPalettesLoop:
  LDA PaletteData,X
  STA PPUDATA
  INX
  CPX #$20
  BNE LoadPalettesLoop

LoadSprites:
  LDX #$00
LoadSpritesLoop:
  LDA SpritesData,X
  STA sprites,X
  INX
  CPX #$10
  BNE LoadSpritesLoop

LoadBackground:
  LDA PPUSTATUS       ; reset latch
  LDA #$20
  STA PPUADDR
  LDA #$00
  STA PPUADDR

  LDX #$00
LoadBackgroundLoop:
  LDA BackgroundData,X
  STA PPUDATA
  INX
  CPX #$80
  BNE LoadBackgroundLoop

LoadAttribute:
  LDA PPUSTATUS
  LDA #$23
  STA PPUADDR
  LDA #$C0
  STA PPUADDR

  LDX #$00
LoadAttributeLoop:
  LDA AttributeData,X
  STA PPUDATA
  INX
  CPX #$08
  BNE LoadAttributeLoop

  JSR EnableRendering

  LDA #$80
  STA posx
  STA posy

Loop:
  JMP Loop

WriteSprite:
  LDA posy
  STA $0200
  LDA #$7F
  STA $0201
  LDA #$00
  STA $0202
  LDA posx
  STA $0203
  RTS

NMI:
  ;NOTE: NMI code goes here
  LDA #$00
  STA OAMADDR
  LDA #$02
  STA OAMDMA

LatchControllers:
  LDA #$01
  STA JOY1
  LDA #$00
  STA JOY1

  LDX #$08
ReadController1Loop:
  LDA JOY1
  LSR A
  ROL controller1
  DEX
  BNE ReadController1Loop

  LDX #$08
ReadController2Loop:
  LDA JOY2
  LSR A
  ROL controller2
  DEX
  BNE ReadController2Loop

HandleUp:
  LDA controller1
  AND #%00001000
  BEQ HandleDown
  LDA posy
  SEC
  SBC #$01
  STA posy

HandleDown:
  LDA controller1
  AND #%00000100
  BEQ HandleLeft
  LDA posy
  CLC
  ADC #$01
  STA posy

HandleLeft:
  LDA controller1
  AND #%00000010
  BEQ HandleRight
  LDA posx
  SEC
  SBC #$01
  STA posx

HandleRight:
  LDA controller1
  AND #%00000001
  BEQ Done
  LDA posx
  CLC
  ADC #$01
  STA posx

Done:
  JSR EnableRendering
  JSR WriteSprite
  RTI



IRQ:
  ;NOTE: IRQ code goes here
  RTI

;----------------------------------------------------------------
; data
;----------------------------------------------------------------
  
  .org $E000

; palettes from tutorial
PaletteData:
  ;background palette data
  ;.db $0F,$31,$32,$33,$0F,$35,$36,$37,$0F,$39,$3A,$3B,$0F,$3D,$3E,$0F
  .db $22,$29,$1A,$0F,$22,$36,$17,$0F,$22,$30,$21,$0F,$22,$27,$17,$0F
  ;sprite palette data
  ;.db $0F,$1C,$15,$14,$0F,$02,$38,$3C,$0F,$1C,$15,$14,$0F,$02,$38,$3C
  .db $22,$1C,$15,$14,$22,$02,$38,$3C,$22,$1C,$15,$14,$22,$02,$38,$3C



SpritesData:
  .db $80,$32,$00,$80
  .db $80,$33,$00,$88
  .db $88,$34,$00,$80
  .db $88,$35,$00,$88

BackgroundData:
  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24  ;;row 1
  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24  ;;all sky

  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24  ;;row 2
  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24  ;;all sky

  .db $24,$24,$24,$24,$45,$45,$24,$24,$45,$45,$45,$45,$45,$45,$24,$24  ;;row 3
  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$53,$54,$24,$24  ;;some brick tops

  .db $24,$24,$24,$24,$47,$47,$24,$24,$47,$47,$47,$47,$47,$47,$24,$24  ;;row 4
  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$55,$56,$24,$24  ;;brick bottoms

AttributeData:
  .db %00000000, %00010000, %01010000, %00010000, %00000000, %00000000, %00000000, %00110000

  .db $24,$24,$24,$24, $47,$47,$24,$24 ,$47,$47,$47,$47, $47,$47,$24,$24 ,$24,$24,$24,$24 ,$24,$24,$24,$24, $24,$24,$24,$24, $55,$56,$24,$24  ;;brick bottoms

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
