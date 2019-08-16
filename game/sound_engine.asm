;----------------------------------------------------------------
; constants
;----------------------------------------------------------------

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

;----------------------------------------------------------------
; variables
;----------------------------------------------------------------

;----------------------------------------------------------------
; program bank(s)
;----------------------------------------------------------------
.org $0300 

SoundInit:
  LDA #$0F
  STA APUFLAGS ;enable Square 1, Square 2, Triangle and Noise channels

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


SoundDisable:

SoundLoad:

SoundPlayFrame:
