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
            LDX   #$3F                    ; store PPU write address ($3F00 is start of pallette memory)
            STX   PPUADDR
            LDX   #$00
            STX   PPUADDR
          
            LDX   #$00
load_plts1: LDA   pallettes,X             ; write background pallette values in PPU memory
            STA   PPUDATA
            INX
            CPX   #$20
            BNE   load_plts1

            LDX   #$00
load_sprts: LDA   sprites,X               ; write sprite data
            STA   $0200,X
            INX
            CPX   #$10
            BNE   load_sprts

vblankwait: BIT PPUSTATUS
            BPL vblankwait
            LDA #%10010000  ; turn on NMIs, sprites use first pattern table
            STA PPUCTRL
            LDA #%00011110  ; render background
            STA PPUMASK

forever:    JMP   forever
.endproc

.segment "VECTORS"                        ; specify interrupt handlers
.addr nmi_handler, reset_handler, irq_handler

.segment "CHR"                            ; CHR-ROM
.incbin "graphics.chr"

.segment "RODATA"                         
pallettes:  
; background pallettes
.byte $11, $11, $11, $11
.byte $11, $11, $11, $11
.byte $11, $11, $11, $11
.byte $11, $11, $11, $11
; sprite pallettes
.byte $11, $09, $19, $29
.byte $11, $03, $21, $31
.byte $11, $06, $16, $26
.byte $11, $09, $19, $29
sprites:
.byte $07, $03, $00, $00
.byte $10, $04, $00, $10
.byte $20, $07, $00, $20
.byte $30, $07, $00, $30

.segment "STARTUP"