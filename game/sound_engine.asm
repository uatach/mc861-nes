
;----------------------------------------------------------------
; program bank(s)
;----------------------------------------------------------------

SoundInit:
  LDA #$0F
  STA APUFLAGS ;enable Square 1, Square 2, Triangle and Noise channels

  ;Square 1
  LDA #%00111000  ;Duty 00, Volume 8 (half volume)
  STA SQ1_ENV

  ;Square 2
  LDA #%01110110  ;Duty 01, Volume 6
  STA SQ2_ENV

  ;Triangle
  LDA #%10000001  ;Triangle channel on
  STA TRI_CTRL

  RTS

OpenSq1:
  ;Square 1
  LDA #%00111000  ;Duty 00, Volume 8 (half volume)
  STA SQ1_ENV
  RTS

CloseSq1:
  ;Square 1
  LDA #%00110000  ;Duty 00, Volume 8 (half volume)
  STA SQ1_ENV
  RTS

OpenSq2:
  ;Square 2
  LDA #%01110110  ;Duty 01, Volume 6
  STA SQ2_ENV
  RTS

CloseSq2:
  ;Square 2
  LDA #%01110000  ;Duty 01, Volume 6
  STA SQ2_ENV
  RTS

OpenTri:
  ;Triangle
  LDA #%10000001  ;Triangle channel on
  STA TRI_CTRL
  RTS

CloseTri:
  ;Triangle
  LDA #%10000000  ;Triangle channel on
  STA TRI_CTRL
  RTS

sound_play_frame:
  RTS

SFX_movingBlockDown:
  lda #%01011000 ;Duty Cycle 00, Volume 8 (half volume) duração no terceiro bit da esquerda pra direita
  sta SQ2_ENV

  lda #$C7   ;$0A9 is an E in NTSC mode
  sta SQ2_LO

  lda #%00100000
  sta SQ2_HI
  RTS

SFX_movingBlocSideway:
  lda #%01011000 ;Duty Cycle 00, Volume 8 (half volume) duração no terceiro bit da esquerda pra direita
  sta SQ2_ENV

  lda #$F2   ;$0A9 is an E in NTSC mode
  sta SQ2_LO

  lda #%00010000
  sta SQ2_HI
  RTS

