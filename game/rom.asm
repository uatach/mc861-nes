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
  S .dsb 8

  ; holds temporary values to free registers locally,
  ; also used to pass parameters to subroutines and the return values.
  T .dsb 8

  ; game state
  state .dsb 1

  ; blocks data
  ; positions of each block, each values represent a position into
  ; a matrix that is used to generate each blocks addres into the
  ; ppu's memory
  blocks .dsb 80
  ; each block's sprites index
  shapes .dsb 80
  ; index into blocks and shapes for the blocks that are falling
  latest .dsb 1

  ; top of each column, each value indicates the maximum position
  ; a block may occupy into each column
  tops .dsb 6
  ; column's index where blocks are falling
  column .dsb 1

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

; PusH Memory with index to stash
.macro PHM addr, idx
  LDAMI addr,idx
  PHA
.endm

; PulL Memory with index from stash
.macro PLM addr, idx
  PLA
  STAMI addr,idx
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
  STM #$02, column
  JSR CreateBlocks

  ; init column tops
  STMI #$48, tops,$00
  STMI #$49, tops,$01
  STMI #$4A, tops,$02
  STMI #$4B, tops,$03
  STMI #$4C, tops,$04
  STMI #$4D, tops,$05

  jsr SoundInit

  ; last step, enables NMI
  JSR EnableRendering

WaitNMI:
  JMP WaitNMI

; include engine de som
  .include "sound_engine.asm"


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
  STMX #$A1, shapes
  STMX #$02, blocks
  INX
  STMX #$99, shapes
  STMX #$02, blocks
  INX
  STMX #$99, shapes
  STMX #$02, blocks
  RTS


; calculates a block address into the ppu memory
; parameters:
; 0 - block index
; returns:
; 0 - high address
; 1 - low address
CalcBlockAddress:
  PHM S,$00
  PHM S,$01

  ; init low address
  LDA #<NAMETABLE0
  CLC
  ADC #$0A
  STA S

  ; init high address
  STMI #>NAMETABLE0, S,$01

  ; load block position
  LDX T
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

  PLM S,$01
  PLM S,$00
  RTS

; removes a block from the ppu memory
; parameters:
; 0 - block index
ClearBlock:
  JSR CalcBlockAddress
  JSR ClearTiles
  RTS

; places a block into the ppu memory
; parameters:
; 0 - block index
DrawBlock:
  LDA T
  PHA
  JSR CalcBlockAddress

  ; loading sprite index
  PLA
  TAX
  LDA shapes,X
  STAMI T,$02

  JSR StoreTiles

  RTS

; parameters:
; 0 - block index
MoveBlockDown:
  ; load column top
  LDX column
  LDA tops,X
  LDX T
  CLC
  CMP blocks,X
  BCC +
  ; block still falling
  TXA
  PHA
  JSR ClearBlock
  PLA
  TAX
  ; update block position
  LDA #ROWSIZE
  CLC
  ADC blocks,X
  STA blocks,X
  
  JSR SFX_movingBlockDown
  RTS
+
  ; block has landed
  ; update top
  LDX column
  LDA tops,X
  SEC
  SBC #$06
  STA tops,X
  ; update latest
  LDA latest
  CLC
  ADC #$02
  STA latest
  ; create new blocks
  JSR CreateBlocks
  ; set column back to start
  STM #$02, column
  RTS

MoveBlockLeft:
  LDX T
  TXA
  PHA
  JSR ClearBlock
  PLA
  TAX
  LDA blocks,X
  SEC
  SBC #$01
  STA blocks,X
  Jsr SFX_movingBlocSideway
  RTS

MoveBlockRight:
  LDX T
  TXA
  PHA
  JSR ClearBlock
  PLA
  TAX
  LDA blocks,X
  CLC
  ADC #$01
  STA blocks,X
  Jsr SFX_movingBlocSideway
  RTS

;----------------------------------------------------------------
;----------------------------------------------------------------

; TODO: rename
StateA:
  ; update tiles
  JSR DrawPositionTiles

  LDA latest
  CLC
  ADC #$01
  STA T
  JSR DrawBlock

  LDA latest
  STA T
  JSR DrawBlock

  JMP UpdateSprites


; TODO: rename
StateB:
  INC counter
  LDA counter
  CMP #$10
  BNE +
  STM #$00, counter
  LDA latest
  STA T
  JSR MoveBlockDown
+
  JMP UpdateSprites


; TODO: rename
StateC:
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

  LDA posy
  SEC
  SBC #$01
  STA posy

HandleDown:
  LDA controller1
  AND #%00000100
  BEQ HandleLeft

  JSR CloseSq1
  JSR CloseSq2
  JSR CloseTri

  LDA posy
  CLC
  ADC #$01
  STA posy

  JMP UpdateSprites


; TODO: rename
StateD:
HandleLeft:
  LDA controller1
  AND #%00000010
  BEQ HandleRight

  LDA column
  CLC
  CMP #$01
  BCC +
  DEC column
  LDA latest
  STA T
  JSR MoveBlockLeft
+

  LDA posx
  SEC
  SBC #$01
  STA posx

HandleRight:
  LDA controller1
  AND #%00000001
  BEQ ++

  LDA column
  CLC
  CMP #$05
  BCS +
  INC column
  LDA latest
  STA T
  JSR MoveBlockRight
+


  LDA posx
  CLC
  ADC #$01
  STA posx

++
  JMP UpdateSprites

;----------------------------------------------------------------
;----------------------------------------------------------------

NMI:
  ; send sprites to PPU
  STM #<SPRITES, OAMADDR
  STM #>SPRITES, OAMDMA

  JSR ReadControllers

  LDA state
  CMP #$00 ; TODO: add constant
  BNE +
  ; update state
  STM #$01, state
  JMP StateA
+

  LDA state
  CMP #$01 ; TODO: add constant
  BNE +
  ; update state
  STM #$02, state
  JMP StateB
+

  LDA state
  CMP #$02 ; TODO: add constant
  BNE +
  ; update state
  STM #$03, state
  JMP StateC
+

  LDA state
  CMP #$03 ; TODO: add constant
  BNE +
  ; update state
  STM #$00, state
  JMP StateD
+

UpdateSprites:
  STMI #$60, T,$00
  STMI posy, T,$01
  STMI #$00, T,$02
  STMI posx, T,$03
  JSR StoreMushroomSprites

  ; clean up PPU
  JSR EnableRendering
  ; graphics updates finished
  jsr sound_play_frame    ;run our sound engine after all drawing code is done.
                            ;this ensures our sound engine gets run once per frame.
 
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
