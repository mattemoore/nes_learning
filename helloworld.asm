.segment "HEADER"
.byte "NES", 26, 2, 1, 0, 0

; PRG-ROM
.segment "CODE"
.proc irq_handler
  RTI
.endproc

.proc nmi_handler
  RTI
.endproc

.proc reset_handler
  SEI
  CLD
  LDX #$00
  STX $2000
  STX $2001
vblankwait:
  BIT $2002
  BPL vblankwait
  JMP main
.endproc

.proc main
  PPUMASK=$2001
  PPUSTATUS=$2002
  PPUADDR=$2006
  PPUDATA=$2007

  ; prep PPU for writing
  LDX PPUSTATUS

  ; store PPU write address ($3F00 is address of first pallette)
  LDX #$3F
  STX PPUADDR
  LDX #$00
  STX PPUADDR

  ; write color value to write address 
  LDA #$29
  STA PPUDATA

  ; draw background
  LDA #%00011110
  STA PPUMASK

forever:
  JMP forever
.endproc

.segment "VECTORS"
.addr nmi_handler, reset_handler, irq_handler

; CHR-ROM
.segment "CHARS"
.res 8192

.segment "STARTUP"