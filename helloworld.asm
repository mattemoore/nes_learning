PPUCTRL=$2000
PPUMASK=$2001
PPUSTATUS=$2002
PPUADDR=$2006
PPUDATA=$2007

.segment "HEADER"                         ; iNes header (e.g. 2x16KB PRG-ROMs, 1x8KB CHR-ROM, mapper 0)
.byte "NES", 26, 2, 1, 0, 0

.segment "CODE"                           ; PRG-ROM
.proc irq_handler                         ; sound/catridge interrupt
            RTI
.endproc

.proc nmi_handler                         ; draw frame interrupt (60/sec)
            RTI
.endproc

.proc reset_handler                       ; startup/reset button interrupt
            SEI                           ; ignore interrupts
            CLD

            LDX #$00                      ; disable rendering during startup
            STX PPUCTRL
            STX PPUMASK

vblankwait: BIT PPUSTATUS                 ; wait until PPU ready
            BPL vblankwait
            JMP main
.endproc

.proc main
            LDX   PPUSTATUS               ; prep PPU for writing

            LDX   #$3F                    ; store PPU write address ($3F00 is address of first pallette)
            STX   PPUADDR
            LDX   #$00
            STX   PPUADDR

            LDA   #$27                    ; write color value to write address 
            STA   PPUDATA

            LDA   #%00011110              ; draw background
            STA   PPUMASK

forever:    JMP   forever
.endproc

.segment "VECTORS"                        ; specify interrupt handlers
.addr nmi_handler, reset_handler, irq_handler

.segment "CHARS"                          ; CHR-ROM
.res 8192

.segment "STARTUP"