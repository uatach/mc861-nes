
;----------------------------------------------------------------
; program bank(s)
;----------------------------------------------------------------
SoundInit:
  LDA #$0F
  STA APUFLAGS ;enable Square 1, Square 2, Triangle and Noise channels

  ;Square 1
  LDA #%00111000  ;Duty 00, Volume 8 (half volume)
  STA SQ1_ENV
  LDA #$C9        ;$0C9 is a C# in NTSC mode
  STA SQ1_LO      ;low 8 bits of period
  LDA #$00
  STA SQ1_HI       ;high 3 bits of period

  ;Square 2
  LDA #%01110110  ;Duty 01, Volume 6
  STA SQ2_ENV
  LDA #$A9        ;$0A9 is an E in NTSC mode
  STA SQ2_HI
  LDA #$00
  STA SQ2_HI

  ;Triangle
  LDA #%10000001  ;Triangle channel on
  STA TRI_CTRL
  LDA #$42        ;$042 is a G# in NTSC mode
  STA TRI_LO
  LDA #$00
  STA TRI_HI
  JSR WaitVBlank
