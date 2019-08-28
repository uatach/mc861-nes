;---------------------------------------------------------------
; memory sections / sizes
; $0000-07FF -  2KB - Internal RAM, chip in the NES
;   $0000-00FF - 256B - Page zero
;   $0100-01FF - 256B - Stack
;   $0200-02FF - 256B - Sprites
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

; stack grows from $01FF to $0100
; TSX gives relative position from $0100
STACK = $0100

; sprite data that is transfered to PPU at the start of every NMI
SPRITES = $0200

NAMETABLE0 = $2000


; game constants

ROWSIZE = $06


;----------------------------------------------------------------
; variables
;----------------------------------------------------------------

  .enum $0000

  ; holds values that should survive jumps to subroutines,
  ; meaning that subroutines must restore these values before
  ; returning.
  ; TODO: improve usages without restoring
  S .dsb 8

  ; holds temporary values to free registers locally,
  ; also used to pass parameters to subroutines.
  T .dsb 8

  ; holds blocks data (color, position) 13*6*2 = 156
  blocks .dsb 80
  colors .dsb 80
  latest .dsb 1
  blockx .dsb 1

  pointerLo .dsb 1
  pointerHi .dsb 1

  ; holds controllers data
  controller1 .dsb 1
  controller2 .dsb 1

  ; TODO: remove?
  posx .dsb 1
  posy .dsb 1
  counter .dsb 1

  .ende

;----------------------------------------------------------------
; useful macros
;----------------------------------------------------------------

; LoaD A from Memory with Index
.macro LDAMI addr, idx
  LDY #idx
  LDA addr,Y
.endm

; LoaD X from Memory with Index
.macro LDXMI addr, idx
  LDY #idx
  LDX addr,Y
.endm

; STore A into Memory with Index
.macro STAMI addr, idx
  LDY #idx
  STA addr,Y
.endm

; STore to Memory
.macro STM val, addr
  LDA val
  STA addr
.endm

; STore to Memory with Index
.macro STMI val, addr, idx
  LDA val
  STAMI addr,idx
.endm

; STore to Memory with X
.macro STMX val, addr
  LDA val
  STA addr,X
.endm


;----------------------------------------------------------------
; iNES header
;----------------------------------------------------------------

  .db "NES", $1a        ; identification of the iNES header
  .db PRG_COUNT         ; number of 16KB PRG-ROM pages
  .db CHR_COUNT         ; number of 8KB CHR-ROM pages
  .db $00|MIRRORING     ; mapper 0 and mirroring
  .dsb 9, $00           ; clear the remaining bytes

;----------------------------------------------------------------
; program bank(s)
;----------------------------------------------------------------

  .base $10000-(PRG_COUNT*$4000) ; aka $8000 or $C000

;----------------------------------------------------------------
; aux routines
;----------------------------------------------------------------

; waits ppu to be ready
WaitVBlank:
  BIT PPUSTATUS
  BPL WaitVBlank
  RTS

; set ppu registers before drawing anything
EnableRendering:
  ; following values explained at:
  ;  http://wiki.nesdev.com/w/index.php/PPU_registers
  STM #%10010000, PPUCTRL
  STM #%00011110, PPUMASK
  LDA #$00
  STA PPUSCROLL
  STA PPUSCROLL
  RTS


;----------------------------------------------------------------
;----------------------------------------------------------------

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

  LDX #$00
ClearMemory:      ; setup ram
  LDA #$00
  STA $0000,X
  STA STACK,X
  STA $0300,X
  STA $0400,X
  STA $0500,X
  STA $0600,X
  STA $0700,X
  LDA #$FE
  STA SPRITES,X
  INX
  BNE ClearMemory

; include engine de som
  .include "sound_engine.asm"

; start loading data into ram and ppu memory

LoadPalettes:
  LDA PPUSTATUS       ; reset latch
  STM #$3F, PPUADDR
  STM #$00, PPUADDR

  LDX #$00
-
  LDA PaletteData,X
  STA PPUDATA
  INX
  CPX #$20
  BNE -


LoadBackground:
  LDA PPUSTATUS       ; reset latch
  STM #>NAMETABLE0, PPUADDR
  STM #<NAMETABLE0, PPUADDR

  STM #<BackgroundData, pointerLo
  STM #>BackgroundData, pointerHi

  LDX #$00
  LDY #$00
--
-
  LDA (pointerLo),Y
  STA PPUDATA
  INY
  CPY #$00
  BNE -

  INC pointerHi
  INX
  CPX #$04
  BNE --


LoadAttribute:
  LDA PPUSTATUS       ; reset latch
  STM #$23, PPUADDR
  STM #$C0, PPUADDR

  LDX #$00
-
  LDA AttributeData,X
  STA PPUDATA
  INX
  CPX #$40
  BNE -

  ; init variables
  LDA #$80
  STA posx
  STA posy

  STM #$00, latest
  STM #$02, blockx
  JSR CreateBlocks

  ; last step, enables NMI
  JSR EnableRendering

WaitNMI:
  JMP WaitNMI

;----------------------------------------------------------------
;----------------------------------------------------------------

ReadControllers:
  STM #$01, JOY1
  STM #$00, JOY1

  LDX #$08
-
  LDA JOY1
  LSR A
  ROL controller1
  DEX
  BNE -

  LDX #$08
-
  LDA JOY2
  LSR A
  ROL controller2
  DEX
  BNE -
  RTS

ClearMushroomSprites:
  LDX T
  LDY #$00
  LDA #$FE
-
  STA SPRITES,X
  INX
  INY
  CPY #$10
  BNE -
  RTS

StoreMushroomSprites:
  ; mushroom top left
  LDX T ; load address

  LDAMI T,$01 ; copy y position
  STA SPRITES,X

  INX
  STMX #$76, SPRITES ; copy sprite index

  INX
  LDAMI T,$02
  STA SPRITES,X ; copy attribute

  INX
  LDAMI T,$03
  STA SPRITES,X ; copy x position

  ; mushroom top right
  INX
  LDAMI T,$01 ; copy y position
  STA SPRITES,X

  INX
  STMX #$77, SPRITES ; copy sprite index

  INX
  LDAMI T,$02
  STA SPRITES,X ; copy attribute

  INX
  LDAMI T,$03
  CLC
  ADC #$08
  STA SPRITES,X ; copy x position

  ; mushroom bottom left
  INX
  LDAMI T,$01 ; copy y position
  CLC
  ADC #$08
  STA SPRITES,X

  INX
  STMX #$78, SPRITES ; copy sprite index

  INX
  LDAMI T,$02
  STA SPRITES,X ; copy attribute

  INX
  LDAMI T,$03
  STA SPRITES,X ; copy x position

  ; mushroom bottom right
  INX
  LDAMI T,$01 ; copy y position
  CLC
  ADC #$08
  STA SPRITES,X

  INX
  STMX #$79, SPRITES ; copy sprite index

  INX
  LDAMI T,$02
  STA SPRITES,X ; copy attribute

  INX
  LDAMI T,$03
  CLC
  ADC #$08
  STA SPRITES,X ; copy x position
  RTS

ClearTiles:
  LDA PPUSTATUS       ; reset latch
  LDAMI T,$00
  STA PPUADDR
  LDAMI T,$01
  STA PPUADDR

  LDA #$24
  STA PPUDATA
  STA PPUDATA

  ; TODO: needs 16-bit addition
  LDA PPUSTATUS       ; reset latch
  LDAMI T,$00
  STA PPUADDR
  LDAMI T,$01
  CLC
  ADC #$20
  STA PPUADDR

  LDA #$24
  STA PPUDATA
  STA PPUDATA
  RTS

StoreTiles:
  LDA PPUSTATUS       ; reset latch
  LDAMI T,$00
  STA PPUADDR
  LDAMI T,$01
  STA PPUADDR

  LDAMI T,$02
  TAX
  STX PPUDATA
  INX
  STX PPUDATA

  ; TODO: needs 16-bit addition
  LDA PPUSTATUS       ; reset latch
  LDAMI T,$00
  STA PPUADDR
  LDAMI T,$01
  CLC
  ADC #$20
  STA PPUADDR

  INX
  STX PPUDATA
  INX
  STX PPUDATA
  RTS

DrawPositionTiles:
  LDA PPUSTATUS       ; reset latch
  STM #$21, PPUADDR
  STM #$82, PPUADDR

  LDA posx
  ROR A
  ROR A
  ROR A
  ROR A
  AND #$0F
  STA PPUDATA

  LDA posx
  AND #$0F
  STA PPUDATA

  STM #$24, PPUDATA

  LDA posy
  ROR A
  ROR A
  ROR A
  ROR A
  AND #$0F
  STA PPUDATA

  LDA posy
  AND #$0F
  STA PPUDATA
  RTS


CreateBlocks:
  LDX latest
  STMX #$02, colors
  STMX #$02, blocks
  INX
  STMX #$01, colors
  STMX #$02, blocks
  INX
  STMX #$00, colors
  STMX #$02, blocks
  RTS


CalcBlockAddress:
  LDA #<NAMETABLE0
  CLC
  ADC #$0A
  STA S

  STMI #>NAMETABLE0, S,$01

  LDX latest
  LDA blocks,X
-
  CLC
  CMP #ROWSIZE
  BCC +

  SEC
  SBC #ROWSIZE
  PHA

  LDA #$40
  CLC
  ADC S
  STA S
  LDAMI S,$01
  ADC #$00
  STAMI S,$01

  PLA
  JMP -
+
  ASL
  CLC
  ADC S
  STAMI T,$01

  LDAMI S,$01
  STAMI T,$00
  RTS

ClearBlock:
  JSR CalcBlockAddress
  JSR ClearTiles
  RTS

; TODO: receive index
DrawBlock:
  JSR CalcBlockAddress
  STMI #$99, T,$02
  JSR StoreTiles
  RTS


MoveBlockDown:
  LDXMI T,$01
  LDA #$4D
  CLC
  CMP blocks,X
  BCC +
  TXA
  PHA
  JSR ClearBlock
  PLA
  TAX
  LDA #ROWSIZE
  CLC
  ADC blocks,X
  STA blocks,X
+
  RTS

MoveBlockLeft:
  LDXMI T,$01
  LDA blocks,X
  SEC
  SBC #$01
  STA blocks,X
  RTS

MoveBlockRight:
  LDXMI T,$01
  LDA blocks,X
  CLC
  ADC #$01
  STA blocks,X
  RTS

;----------------------------------------------------------------
;----------------------------------------------------------------

NMI:
  ; send sprites to PPU
  STM #<SPRITES, OAMADDR
  STM #>SPRITES, OAMDMA

  ; update tiles
  JSR DrawPositionTiles

  INC counter
  LDA counter
  CMP #$00
  BNE +
  LDA latest
  STAMI T,$01
  JSR MoveBlockDown
+

  JSR DrawBlock

  ; clean up PPU
  JSR EnableRendering
  ; graphics updates finished

  JSR ReadControllers


; TODO: improve
HandleA:
  LDA controller1
  AND #%10000000
  BEQ HandleB

  ; disables sprite
  STM #$70, T
  JSR ClearMushroomSprites

HandleB:
  LDA controller1
  AND #%01000000
  BEQ HandleUp

  ; enables sprite
  STMI #$70, T,$00
  STMI #$30, T,$01
  STMI #$00, T,$02
  STMI #$30, T,$03
  JSR StoreMushroomSprites


HandleUp:
  LDA controller1
  AND #%00001000
  BEQ HandleDown

  LDA #%10000001  ;Triangle channel on
  STA $4008
  LDA #$44        ;$042 is a G# in NTSC mode
  STA $400A
  LDA #$00
  STA $400B


  LDA posy
  SEC
  SBC #$01
  STA posy

HandleDown:
  LDA controller1
  AND #%00000100
  BEQ HandleLeft

  LDA #%10000000  ;Triangle channel off
  STA $4008
  LDA #$42        ;$042 is a G# in NTSC mode
  STA $400A
  LDA #$00
  STA $400B

  LDA posy
  CLC
  ADC #$01
  STA posy

HandleLeft:
  LDA controller1
  AND #%00000010
  BEQ HandleRight

  LDA #%10000001  ;Triangle channel on
  STA $4008
  LDA #$32        ;$038 is a G# in NTSC mode
  STA $400A
  LDA #$00
  STA $400B

  LDA blockx
  CLC
  CMP #$01
  BCC +
  DEC blockx
  LDA latest
  STAMI T,$01
  JSR MoveBlockLeft
+

  LDA posx
  SEC
  SBC #$01
  STA posx

HandleRight:
  LDA controller1
  AND #%00000001
  BEQ UpdateSprites

  LDA #%10000001  ;Triangle channel on
  STA $4008
  LDA #$36        ;$042 is a G# in NTSC mode
  STA $400A
  LDA #$00
  STA $400B

  LDA blockx
  CLC
  CMP #$05
  BCS +
  INC blockx
  LDA latest
  STAMI T,$01
  JSR MoveBlockRight
+


  LDA posx
  CLC
  ADC #$01
  STA posx


UpdateSprites:
  STMI #$60, T,$00
  STMI posy, T,$01
  STMI #$00, T,$02
  STMI posx, T,$03
  JSR StoreMushroomSprites

  RTI

;----------------------------------------------------------------
;----------------------------------------------------------------

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
  .db $22,$29,$1A,$0F,$22,$36,$17,$0F,$22,$30,$21,$0F,$22,$15,$37,$27
  ;sprite palette data
  ;.db $0F,$1C,$15,$14,$0F,$02,$38,$3C,$0F,$1C,$15,$14,$0F,$02,$38,$3C
  ;.db $22,$1C,$15,$14,$22,$02,$38,$3C,$22,$1C,$15,$14,$22,$02,$38,$3C
  .db $22,$15,$37,$27,$22,$02,$38,$3C,$22,$1C,$15,$14,$22,$02,$38,$3C


SpritesData:
  .db $00,$76,$00,$70
  .db $00,$77,$00,$78
  .db $08,$78,$00,$70
  .db $08,$79,$00,$78


BackgroundData:
  ; row 0
  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24

  ; row 1
  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24

  ; row 2
  .db $24,$24,$36,$37,$24,$24,$24,$24,$45,$45,$24,$24,$24,$24,$24,$24
  .db $24,$24,$24,$24,$24,$24,$45,$45,$24,$24,$24,$24,$24,$24,$24,$24

  ; row 3
  .db $24,$35,$25,$25,$38,$24,$24,$24,$47,$47,$24,$24,$24,$24,$24,$24
  .db $24,$24,$24,$24,$24,$24,$47,$47,$24,$24,$24,$24,$24,$24,$24,$35

  ; row 4
  .db $24,$39,$3A,$3B,$3C,$24,$24,$24,$47,$47,$24,$24,$24,$24,$24,$24
  .db $24,$24,$24,$24,$24,$24,$47,$47,$24,$24,$24,$24,$24,$24,$24,$39

  ; row 5
  .db $37,$24,$24,$24,$24,$24,$24,$24,$47,$47,$24,$24,$24,$24,$24,$24
  .db $24,$24,$24,$24,$24,$24,$47,$47,$24,$24,$24,$24,$24,$24,$24,$24

  ; row 6
  .db $25,$38,$24,$24,$24,$24,$24,$24,$47,$47,$24,$24,$24,$24,$24,$24
  .db $24,$24,$24,$24,$24,$24,$47,$47,$24,$24,$24,$24,$24,$24,$24,$24

  ; row 7
  .db $3B,$3C,$24,$24,$24,$24,$24,$24,$47,$47,$24,$24,$24,$24,$24,$24
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
  .db $24,$24,$24,$24,$24,$24,$47,$47,$24,$24,$24,$36,$37,$24,$24,$24

  ; row 12
  .db $24,$24,$24,$24,$24,$24,$24,$24,$47,$47,$24,$24,$24,$24,$24,$24
  .db $24,$24,$24,$24,$24,$24,$47,$47,$24,$24,$35,$25,$25,$38,$24,$24

  ; row 13
  .db $24,$24,$24,$24,$24,$24,$24,$24,$47,$47,$24,$24,$24,$24,$24,$24
  .db $24,$24,$24,$24,$24,$24,$47,$47,$24,$24,$39,$3A,$3B,$3C,$24,$24

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
  .db $24,$24,$31,$32,$24,$24,$24,$24,$47,$47,$24,$24,$24,$24,$24,$24
  .db $24,$24,$24,$24,$24,$24,$47,$47,$24,$24,$24,$24,$24,$24,$24,$24

  ; row 26
  .db $24,$30,$26,$34,$33,$24,$24,$24,$47,$47,$24,$24,$24,$24,$24,$24
  .db $24,$24,$24,$24,$24,$24,$47,$47,$24,$24,$36,$37,$24,$24,$24,$24

  ; row 27
  .db $30,$26,$26,$26,$26,$33,$24,$24,$47,$47,$24,$24,$24,$24,$24,$24
  .db $24,$24,$24,$24,$24,$24,$47,$47,$24,$35,$25,$25,$38,$24,$24,$35

  ; row 28
  .db $B4,$B5,$B4,$B5,$B4,$B5,$B4,$B5,$B4,$B5,$B4,$B5,$B4,$B5,$B4,$B5
  .db $B4,$B5,$B4,$B5,$B4,$B5,$B4,$B5,$B4,$B5,$B4,$B5,$B4,$B5,$B4,$B5

  ; row 29
  .db $B6,$B7,$B6,$B7,$B6,$B7,$B6,$B7,$B6,$B7,$B6,$B7,$B6,$B7,$B6,$B7
  .db $B6,$B7,$B6,$B7,$B6,$B7,$B6,$B7,$B6,$B7,$B6,$B7,$B6,$B7,$B6,$B7

AttributeData:
  .db %10100000, %00100000, %11011100, %11111111, %11111111, %01110011, %00000000, %10000000
  .db %00101010, %00000010, %11011101, %11111111, %11111111, %01110111, %00000000, %00001000
  .db %00000000, %00000000, %11011101, %11111111, %11111111, %01110111, %10000000, %00100000
  .db %00000000, %00000000, %11011101, %11111111, %11111111, %01110111, %00001000, %00000010
  .db %00000000, %00000000, %11011101, %11111111, %11111111, %01110111, %00000000, %00000000
  .db %00000000, %00000000, %11011101, %11111111, %11111111, %01110111, %00000000, %00000000
  .db %00000000, %00000000, %11011101, %11111111, %11111111, %01110111, %00000000, %00000000
  .db %01010101, %01010101, %01010101, %01010101, %01010101, %01010101, %01010101, %01010101


;-------------------------------------------------------------------------------------------------------------------------------------;
;--------------------------------------- Tabela de notas -----------------------------------------------------------------------------;
;-------------------------------------------------------------------------------------------------------------------------------------;
;Note: octaves in music traditionally start from C, not A.
;      I've adjusted my octave numbers to reflect this.
note_table:
    .word                                                                $07F1, $0780, $0713 ; A1-B1 ($00-$02)
    .word $06AD, $064D, $05F3, $059D, $054D, $0500, $04B8, $0475, $0435, $03F8, $03BF, $0389 ; C2-B2 ($03-$0E)
    .word $0356, $0326, $02F9, $02CE, $02A6, $027F, $025C, $023A, $021A, $01FB, $01DF, $01C4 ; C3-B3 ($0F-$1A)
    .word $01AB, $0193, $017C, $0167, $0151, $013F, $012D, $011C, $010C, $00FD, $00EF, $00E2 ; C4-B4 ($1B-$26)
    .word $00D2, $00C9, $00BD, $00B3, $00A9, $009F, $0096, $008E, $0086, $007E, $0077, $0070 ; C5-B5 ($27-$32)
    .word $006A, $0064, $005E, $0059, $0054, $004F, $004B, $0046, $0042, $003F, $003B, $0038 ; C6-B6 ($33-$3E)
    .word $0034, $0031, $002F, $002C, $0029, $0027, $0025, $0023, $0021, $001F, $001D, $001B ; C7-B7 ($3F-$4A)
    .word $001A, $0018, $0017, $0015, $0014, $0013, $0012, $0011, $0010, $000F, $000E, $000D ; C8-B8 ($4B-$56)
    .word $000C, $000C, $000B, $000A, $000A, $0009, $0008                                    ; C9-F#9 ($57-$5D)

    ;Note: octaves in music traditionally start at C, not A

;Octave 1
A1 = $00    ;"1" means octave 1.
As1 = $01   ;"s" means "sharp"
Bb1 = $01   ;"b" means "flat".  A# == Bb
B1 = $02

;Octave 2
C2 = $03
Cs2 = $04
Db2 = $04
D2 = $05
;...
A2 = $0C
As2 = $0D
Bb2 = $0D
B2 = $0E
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
