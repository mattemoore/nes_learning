.include "constants.inc"
.include "header.inc"

.segment "CODE"                           ; PRG-ROM
.proc irq_handler                         ; sound/catridge interrupt
            RTI
.endproc

.proc nmi_handler                         ; draw frame interrupt (60/sec)
            LDA   #$00                    ; transfer a page of OAM buffer ($0200-$02FF) into PPU
            STA   OAMADDR
            LDA   #$02
            STA   OAMDMA
            LDA   #%10000000              ; turn on NMIs, sprites use first pattern table
            STA   PPUCTRL
            LDA   #%00011110              ; render background
            STA   PPUMASK
            INC   CAM_X
            LDA   CAM_X                   ; update camera position
            STA   PPUSCROLL
            LDA   CAM_Y
            STA   PPUSCROLL

            RTI
.endproc

.proc reset_handler                       ; startup/reset button interrupt
            SEI                           ; ignore interrupts
            CLD

            LDX #$00                      ; disable rendering during startup
            STX PPUCTRL
            STX PPUMASK

            JMP main
.endproc

.export main                              ; make main referrable
.proc main
            ; write palletes to PPU
            LDX   PPUSTATUS               ; prep PPU for writing
            LDX   #$3F                    ; store PPU write address ($3F00 is start of pallette memory)
            STX   PPUADDR
            LDX   #$00                    
            STX   PPUADDR
            LDX   #$00
load_plts:  LDA   pallettes,X
            STA   PPUDATA
            INX
            CPX   #$20
            BNE   load_plts

            ; write sprites to OAM buffer
            LDX   #$00
load_sprts: LDA   sprites,X               
            STA   $0200,X
            INX
            CPX   #$10
            BNE   load_sprts
            
            LDX   #<screen1
            LDY   #>screen1
            LDA   #$00
            JSR   load_screen

            LDX   #<screen2
            LDY   #>screen2
            LDA   #$01
            JSR   load_screen

vblankwait: BIT   PPUSTATUS
            BPL   vblankwait
vblankwait2:BIT   PPUSTATUS
            BPL   vblankwait2
            LDA   #%10000000              ; turn on NMIs
            STA   PPUCTRL

            LDA   #$00
            STA   CAM_Y
            STA   CAM_X
forever:    
            JMP   forever
.endproc

.include "helpers/load_screen.asm"
; TODO: background scrolling 2 nametables 
; TODO: background scrolling >2 namteables 
; TODO: input and hero movement
; TODO: scroll > 2 screens based on hero movement

.segment "VECTORS"                        ; specify interrupt handlers
.addr nmi_handler, reset_handler, irq_handler

.segment "CHR"                            ; CHR-ROM
.incbin "graphics.chr"

.segment "RODATA"                                    
.include "pallettes.asm"
.include "sprites.asm"
.include "screen1.asm"
.include "screen2.asm"