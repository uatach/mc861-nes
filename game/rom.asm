
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

; number of PRG pages
PRG_COUNT = 1 ; 1 = 16KB, 2 = 32KB

; number of CHR pages
CHR_COUNT = 1 ; 1 = 8KB, 2 = 16KB

; TODO: explain
; %0000 = horizontal, %0001 = vertical, %1000 = four-screen
MIRRORING = %0001

; PPU registers
PPUCTRL = $2000
PPUMASK = $2001
PPUSTATUS = $2002
PPUSCROLL = $2005
PPUADDR = $2006
PPUDATA = $2007

; OAM registers
OAMADDR = $2003
OAMDATA = $2004
OAMDMA = $4014

; APU registers
APUFLAGS = $4015
SQ1_ENV = $4000
SQ1_LO  = $4002
SQ1_HI = $4003
SQ2_ENV = $4004
SQ2_SWEEP = $4005
SQ2_LO  = $4006
SQ2_HI = $4007
TRI_CTRL = $4008
TRI_LO = $400A
TRI_HI = $400B

JOY1 = $4016
JOY2 = $4017

SPRITES = $0200

;----------------------------------------------------------------
; variables
;----------------------------------------------------------------

  .enum $0000

  ; NOTE: declare variables using the DSB and DSW directives

  pointerLo .dsb 1
  pointerHi .dsb 1

  ; holds controllers data
  controller1 .dsb 1
  controller2 .dsb 1

  ; TODO: remove
  posx .dsb 1
  posy .dsb 1
  counter .dsb 1

  .ende

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

; aux routines

; waits ppu to be ready
WaitVBlank:
  BIT PPUSTATUS
  BPL WaitVBlank
  RTS

; set ppu registers before drawing anything
EnableRendering:
  ; following values explained at:
  ;  http://wiki.nesdev.com/w/index.php/PPU_registers
  LDA #%10010000
  STA PPUCTRL
  LDA #%00011110
  STA PPUMASK
  LDA #$00
  STA PPUSCROLL
  STA PPUSCROLL
  RTS

; TODO: remove
WriteSprite:
  LDA posy
  STA $0210
  LDA #$7F
  STA $0211
  LDA #$00
  STA $0212
  LDA posx
  STA $0213
  RTS


RESET:
  ; init code based on:
  ;  http://wiki.nesdev.com/w/index.php/Init_code
  SEI             ; disable IRQs
  CLD             ; disable decimal mode
  LDX #$00
  STX $4015
  LDX #$40
  STX $4017       ; disable APU IRQ
  LDX #$FF
  TXS             ; set up stack
  INX
  STX PPUCTRL     ; disable NMI
  STX PPUMASK     ; disable rendering
  STX $4010       ; disable DMC IRQ
  BIT PPUSTATUS   ; clean up vblank

  JSR WaitVBlank

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

  ; setup APU
  LDA #$0F
  STA APUFLAGS

  ; TODO: remove
  ; eternal beep
  ;Square 1
  LDA #%00111000  ;Duty 00, Volume 8 (half volume)
  STA $4000
  LDA #$C9        ;$0C9 is a C# in NTSC mode
  STA $4002       ;low 8 bits of period
  LDA #$00
  STA $4003       ;high 3 bits of period

  ;Square 2
  LDA #%01110110  ;Duty 01, Volume 6
  STA $4004
  LDA #$A9        ;$0A9 is an E in NTSC mode
  STA $4006
  LDA #$00
  STA $4007

  ;Triangle
  LDA #%10000001  ;Triangle channel on
  STA $4008
  LDA #$42        ;$042 is a G# in NTSC mode
  STA $400A
  LDA #$00
  STA $400B

  JSR WaitVBlank
  ; end of init code

; start loading data into ram and ppu memory

LoadPalettes:
  LDA PPUSTATUS       ; reset latch
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
  STA SPRITES,X
  INX
  CPX #$10
  BNE LoadSpritesLoop

LoadBackground:
  LDA PPUSTATUS       ; reset latch
  LDA #$20
  STA PPUADDR
  LDA #$00
  STA PPUADDR

  LDA #<BackgroundData
  STA pointerLo
  LDA #>BackgroundData
  STA pointerHi

  LDX #$00
  LDY #$00
LoadBackgroundOutsideLoop:
LoadBackgroundInsideLoop:
  LDA (pointerLo),Y
  STA PPUDATA
  INY
  CPY #$00
  BNE LoadBackgroundInsideLoop

  INC pointerHi
  INX
  CPX #$04
  BNE LoadBackgroundOutsideLoop

LoadAttribute:
  LDA PPUSTATUS       ; reset latch
  LDA #$23
  STA PPUADDR
  LDA #$C0
  STA PPUADDR

  LDX #$00
LoadAttributeLoop:
  LDA AttributeData,X
  STA PPUDATA
  INX
  CPX #$40
  BNE LoadAttributeLoop

  JSR EnableRendering

  ; init variables
  LDA #$80
  STA posx
  STA posy

  LDA #$00
  STA counter

Loop:
  ; waits for NMI IRQs
  JMP Loop


NMI:
  ;NOTE: NMI code goes here
  LDA #<SPRITES
  STA OAMADDR
  LDA #>SPRITES
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

  JSR WriteSprite

; TODO: improve
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
  BEQ UpdateSprites
  LDA posx
  CLC
  ADC #$01
  STA posx

UpdateSprites:
  INC counter
  LDA counter
  CMP #$00
  BNE Done

  LDX #$00
UpdateSpritesLoop:
  LDA SPRITES,X
  CLC
  ADC #$10
  STA SPRITES,X
  TXA
  ADC #$04
  TAX
  CPX #$10
  BNE UpdateSpritesLoop


Done:
  JSR EnableRendering
  RTI


IRQ:
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
  .db $00,$76,$00,$71
  .db $00,$77,$00,$79
  .db $08,$78,$00,$71
  .db $08,$79,$00,$79


BackgroundData:
  ; row 0
  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24

  ; row 1
  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24

  ; row 2
  .db $24,$24,$24,$24,$24,$24,$24,$24,$45,$45,$24,$24,$24,$24,$24,$24
  .db $24,$24,$24,$24,$24,$24,$45,$45,$24,$24,$24,$24,$24,$24,$24,$24

  ; row 3
  .db $24,$24,$24,$24,$24,$24,$24,$24,$47,$47,$24,$24,$24,$24,$24,$24
  .db $24,$24,$24,$24,$24,$24,$47,$47,$24,$24,$24,$24,$24,$24,$24,$24

  ; row 4
  .db $24,$24,$24,$24,$24,$24,$24,$24,$47,$47,$24,$24,$24,$24,$24,$24
  .db $24,$24,$24,$24,$24,$24,$47,$47,$24,$24,$24,$24,$24,$24,$24,$24

  ; row 5
  .db $24,$24,$24,$24,$24,$24,$24,$24,$47,$47,$24,$24,$24,$24,$24,$24
  .db $24,$24,$24,$24,$24,$24,$47,$47,$24,$24,$24,$24,$24,$24,$24,$24

  ; row 6
  .db $24,$24,$24,$24,$24,$24,$24,$24,$47,$47,$24,$24,$24,$24,$24,$24
  .db $24,$24,$24,$24,$24,$24,$47,$47,$24,$24,$24,$24,$24,$24,$24,$24

  ; row 7
  .db $24,$24,$24,$24,$24,$24,$24,$24,$47,$47,$24,$24,$24,$24,$24,$24
  .db $24,$24,$24,$24,$24,$24,$47,$47,$24,$24,$24,$24,$24,$24,$24,$24

  ; row 8
  .db $24,$24,$24,$24,$24,$24,$24,$24,$47,$47,$24,$24,$24,$24,$24,$24
  .db $24,$24,$24,$24,$24,$24,$47,$47,$24,$24,$24,$24,$24,$24,$24,$24

  ; row 9
  .db $24,$24,$24,$24,$24,$24,$24,$24,$47,$47,$24,$24,$24,$24,$24,$24
  .db $24,$24,$24,$24,$24,$24,$47,$47,$24,$24,$24,$24,$24,$24,$24,$24

  ; row 10
  .db $24,$24,$24,$24,$24,$24,$24,$24,$47,$47,$24,$24,$24,$24,$24,$24
  .db $24,$24,$24,$24,$24,$24,$47,$47,$24,$24,$24,$24,$24,$24,$24,$24

  ; row 11
  .db $24,$24,$24,$24,$24,$24,$24,$24,$47,$47,$24,$24,$24,$24,$24,$24
  .db $24,$24,$24,$24,$24,$24,$47,$47,$24,$24,$24,$24,$24,$24,$24,$24

  ; row 12
  .db $24,$24,$24,$24,$24,$24,$24,$24,$47,$47,$24,$24,$24,$24,$24,$24
  .db $24,$24,$24,$24,$24,$24,$47,$47,$24,$24,$24,$24,$24,$24,$24,$24

  ; row 13
  .db $24,$24,$24,$24,$24,$24,$24,$24,$47,$47,$24,$24,$24,$24,$24,$24
  .db $24,$24,$24,$24,$24,$24,$47,$47,$24,$24,$24,$24,$24,$24,$24,$24

  ; row 14
  .db $24,$24,$24,$24,$24,$24,$24,$24,$47,$47,$24,$24,$24,$24,$24,$24
  .db $24,$24,$24,$24,$24,$24,$47,$47,$24,$24,$24,$24,$24,$24,$24,$24

  ; row 15
  .db $24,$24,$24,$24,$24,$24,$24,$24,$47,$47,$24,$24,$24,$24,$24,$24
  .db $24,$24,$24,$24,$24,$24,$47,$47,$24,$24,$24,$24,$24,$24,$24,$24

  ; row 16
  .db $24,$24,$24,$24,$24,$24,$24,$24,$47,$47,$24,$24,$24,$24,$24,$24
  .db $24,$24,$24,$24,$24,$24,$47,$47,$24,$24,$24,$24,$24,$24,$24,$24

  ; row 17
  .db $24,$24,$24,$24,$24,$24,$24,$24,$47,$47,$24,$24,$24,$24,$24,$24
  .db $24,$24,$24,$24,$24,$24,$47,$47,$24,$24,$24,$24,$24,$24,$24,$24

  ; row 18
  .db $24,$24,$24,$24,$24,$24,$24,$24,$47,$47,$24,$24,$24,$24,$24,$24
  .db $24,$24,$24,$24,$24,$24,$47,$47,$24,$24,$24,$24,$24,$24,$24,$24

  ; row 19
  .db $24,$24,$24,$24,$24,$24,$24,$24,$47,$47,$24,$24,$24,$24,$24,$24
  .db $24,$24,$24,$24,$24,$24,$47,$47,$24,$24,$24,$24,$24,$24,$24,$24

  ; row 20
  .db $24,$24,$24,$24,$24,$24,$24,$24,$47,$47,$24,$24,$24,$24,$24,$24
  .db $24,$24,$24,$24,$24,$24,$47,$47,$24,$24,$24,$24,$24,$24,$24,$24

  ; row 21
  .db $24,$24,$24,$24,$24,$24,$24,$24,$47,$47,$24,$24,$24,$24,$24,$24
  .db $24,$24,$24,$24,$24,$24,$47,$47,$24,$24,$24,$24,$24,$24,$24,$24

  ; row 22
  .db $24,$24,$24,$24,$24,$24,$24,$24,$47,$47,$24,$24,$24,$24,$24,$24
  .db $24,$24,$24,$24,$24,$24,$47,$47,$24,$24,$24,$24,$24,$24,$24,$24

  ; row 23
  .db $24,$24,$24,$24,$24,$24,$24,$24,$47,$47,$24,$24,$24,$24,$24,$24
  .db $24,$24,$24,$24,$24,$24,$47,$47,$24,$24,$24,$24,$24,$24,$24,$24

  ; row 24
  .db $24,$24,$24,$24,$24,$24,$24,$24,$47,$47,$24,$24,$24,$24,$24,$24
  .db $24,$24,$24,$24,$24,$24,$47,$47,$24,$24,$24,$24,$24,$24,$24,$24

  ; row 25
  .db $24,$24,$24,$24,$24,$24,$24,$24,$47,$47,$24,$24,$24,$24,$24,$24
  .db $24,$24,$24,$24,$24,$24,$47,$47,$24,$24,$24,$24,$24,$24,$24,$24

  ; row 26
  .db $24,$24,$24,$24,$24,$24,$24,$24,$47,$47,$24,$24,$24,$24,$24,$24
  .db $24,$24,$24,$24,$24,$24,$47,$47,$24,$24,$24,$24,$24,$24,$24,$24

  ; row 27
  .db $24,$24,$24,$24,$24,$24,$24,$24,$47,$47,$24,$24,$24,$24,$24,$24
  .db $24,$24,$24,$24,$24,$24,$47,$47,$24,$24,$24,$24,$24,$24,$24,$24

  ; row 28
  .db $B4,$B5,$B4,$B5,$B4,$B5,$B4,$B5,$B4,$B5,$B4,$B5,$B4,$B5,$B4,$B5
  .db $B4,$B5,$B4,$B5,$B4,$B5,$B4,$B5,$B4,$B5,$B4,$B5,$B4,$B5,$B4,$B5

  ; row 29
  .db $B6,$B7,$B6,$B7,$B6,$B7,$B6,$B7,$B6,$B7,$B6,$B7,$B6,$B7,$B6,$B7
  .db $B6,$B7,$B6,$B7,$B6,$B7,$B6,$B7,$B6,$B7,$B6,$B7,$B6,$B7,$B6,$B7

AttributeData:
  .db %00000000, %00000000, %00010000, %00000000, %00000000, %01000000, %00000000, %00000000
  .db %00000000, %00000000, %00010001, %00000000, %00000000, %01000100, %00000000, %00000000
  .db %00000000, %00000000, %00010001, %00000000, %00000000, %01000100, %00000000, %00000000
  .db %00000000, %00000000, %00010001, %00000000, %00000000, %01000100, %00000000, %00000000
  .db %00000000, %00000000, %00010001, %00000000, %00000000, %01000100, %00000000, %00000000
  .db %00000000, %00000000, %00010001, %00000000, %00000000, %01000100, %00000000, %00000000
  .db %00000000, %00000000, %00010001, %00000000, %00000000, %01000100, %00000000, %00000000
  .db %00000101, %00000101, %00000101, %00000101, %00000101, %01000101, %00000101, %00000101


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
