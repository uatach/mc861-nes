
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
