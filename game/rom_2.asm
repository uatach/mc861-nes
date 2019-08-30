
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
PRG_COUNT = 2 ; 1 = 16KB, 2 = 32KB

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

; channel 1 _quadrada
APUFLAGS =    $4015
SQ1_ENV =     $4000
SQ1_LO  =     $4002
SQ1_HI =      $4003
; channel 2_ quadrada
SQ2_ENV =     $4004
SQ2_SWEEP =   $4005
SQ2_LO =      $4006
SQ2_HI =      $4007
; channel 3_ trinagular

TRI_CTRL =    $4008

; channel 4_ noise  
NOISE_ENV =   $400C


JOY1 = $4016
JOY2 = $4017

;----------------------------------------------------------------
; variables
;----------------------------------------------------------------

  .enum $0000

  ; NOTE: declare variables using the DSB and DSW directives

  ; TODO: explain
  sprites .dsb 16

  ; holds controllers data
  controller1 .dsb 1
  controller2 .dsb 1

  ; TODO: remove
  posx .dsb 1
  posy .dsb 1

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
  STA $0200
  LDA #$7F
  STA $0201
  LDA #$00
  STA $0202
  LDA posx
  STA $0203
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



; Waki ESTÁ FAZENDO TESTE AQUI, QUALQUER CODIGO BIZARRO QUE ESTIVER AQUI AINDA ESTÁ SENDO TESTADO.

  ; setup APU
  LDA #$0F
  STA APUFLAGS
  JSR WaitVBlank



;-------------------------------------------------------------------------------------------------------------------------------------;
;--------------------------------------- Sound Engine    -----------------------------------------------------------------------------;
;-------------------------------------------------------------------------------------------------------------------------------------;


sound_disable_flag =  $0300 ;sound engine variables will be on the $0300 page of RAM
 

 ;  .bank 0

    .org $8000  ;we have two 16k PRG banks now.  We will stick our sound engine in the first one, which starts at $8000.

sound_init:
    lda #$0F
    sta $4015   ;enable Square 1, Square 2, Triangle and Noise channels
 
    lda #$30
    sta $4000   ;set Square 1 volume to 0
    sta $4004   ;set Square 2 volume to 0
    sta $400C   ;set Noise volume to 0
    lda #$80
    sta $4008   ;silence Triangle
 
    lda #$00
    sta sound_disable_flag  ;clear disable flag
 
    ;later, if we have other variables we want to initialize, we will do that here.
 
    rts
 
sound_disable:
    lda #$00
    sta $4015   ;disable all channels
    lda #$01
    sta sound_disable_flag  ;set disable flag
    rts

sound_load:
    ;nothing here yet
    rts
 
sound_play_frame:
    lda sound_disable_flag
    bne done       ;if disable flag is set, don't advance a frame
    ;nothing here yet
done:
    rts






  ; TODO: remove
  ; eternal beep
 ; LDA #%10111111
 ; STA SQ1_ENV
 ; LDA #$C9
  ;STA SQ1_LO
  ;LDA #$00
  ;STA SQ1_HI

  ;test channel 2
  ;LDA #%00111000 ;Duty Cycle 00, Volume 8 (half volume)
  ;STA SQ2_ENV
; 
;  LDA #$B8   ;$0A9 is an E in NTSC mode
;  STA SQ2_LO
; 
;  LDA #$00
;  STA SQ2_HI

  ;TESTE DE SOM  DO CANAL DO TRIANGULO
;  lda #%00000100 ;enable Triangle channel
;    sta $4015;;

;    lda #%10000001 ;disable counters, non-zero Value turns channel on
 ;   sta $4008
 
  ;  lda #$42   ;a period of $042 plays a G# in NTSC mode.
   ; sta $400A
 
    ;lda #$00
   ; sta $400B


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
  CPX #$08
  BNE LoadAttributeLoop

  JSR EnableRendering

  ; init variables
  LDA #$80
  STA posx
  STA posy

Loop:
  ; waits for NMI IRQs
  JMP Loop


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

;Octave 3
C3 = $0F
;... etc


;-------------------------------------------------------------------------------------------------------------------------------------;





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
