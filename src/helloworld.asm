.include "constants.inc"
.include "header.inc"

.segment "CODE"                           ; PRG-ROM
.proc irq_handler                         ; sound/catridge interrupt
            RTI
.endproc

.proc nmi_handler                         ; draw frame interrupt (60/sec)
            LDA #$00                      ; transfer a page of OAM buffer ($0200-$02FF) into PPU
            STA OAMADDR
            LDA #$02
            STA OAMDMA
            RTI
.endproc

.import reset_handler                     ; imported reset handler

.export main                              ; make main referrable
.proc main
            LDX   PPUSTATUS               ; prep PPU for writing

            ; write pallette values in PPU memory
            LDX   #$3F                    ; store PPU write address ($3F00 is address of first pallette)
            STX   PPUADDR
            LDX   #$00
            STX   PPUADDR
            LDA   #$0F
            STA   PPUDATA                 ; each write increments PPUADDR by one byte
            LDA   #$09
            STA   PPUDATA
            LDA   #$19
            STA   PPUDATA
            LDA   #$29

            ; copy sprite data to OAM buffer in CPU memory
            ; NMI interrupt then copies OAM buffer to PPU memory
            LDA   #$70                    ; Y-coordinate
            STA   $0200
            LDA   #$03                    ; tile number
            STA   $0201
            LDA   #$00                    ; attributes flag
            STA   $0202
            LDA   #$80                    ; X-coordinate
            STA   $0203

vblankwait: BIT PPUSTATUS
            BPL vblankwait
            LDA #%10010000  ; turn on NMIs, sprites use first pattern table
            STA PPUCTRL
            LDA #%00011110  ; turn on screen
            STA PPUMASK

forever:    JMP   forever
.endproc

.segment "VECTORS"                        ; specify interrupt handlers
.addr nmi_handler, reset_handler, irq_handler

.segment "CHR"                            ; CHR-ROM
.incbin "graphics.chr"

.segment "STARTUP"