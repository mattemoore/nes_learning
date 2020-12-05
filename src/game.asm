.include "constants.inc"
.include "header.inc"

.segment "CODE"                           ; PRG-ROM
.proc irq_handler                         ; sound/catridge interrupt
            RTI
.endproc

.proc nmi_handler
            ; transfer a page of OAM (sprite) buffer ($0200-$02FF) into PPU
            LDA   #$00  
            STA   OAMADDR
            LDA   #$02
            STA   OAMDMA

            ; draw off screen columns if scrolled 16px
load_seam:
            LDA   CAM_X
            AND   #%00001111              ; check if multiple of 16 (16px:1 background tile)
            BNE   done_cols 
            ; find which column  to draw to (i.e which 16x16 column in which nametable)
            LDA   CAM_X
            LSR   A
            LSR   A
            LSR   A 
            LSR   A
            STA   DRAW_COL
            ASL   A
            STA   COL_LO

            ; TODO: draw a column of something in proper column in proper nametable 
            LDA   NAMETABLE
            EOR   #$01
            CMP   #$00
            BEQ   set_name0
            LDA   #$24
            STA   COL_HIGH
            JMP   start_cols
set_name0:  
            LDA   #$20
            STA   COL_HIGH
start_cols:
            LDY   #$02                    ; write two columns of 8x8 tiles
write_col:                     
            LDA   #%00000100              ; write one column of 8x8 tiles
            STA   PPUCTRL
            LDA   PPUSTATUS
            LDX   COL_HIGH
            STX   PPUADDR
            LDX   COL_LO
            ; LDX   DRAW_COL
            STX   PPUADDR
            LDX   #$1E
write_byte:                         
            LDA   $FF                 ; TODO: point to the right part of map to load in
            STA   PPUDATA
            DEX
            BNE   write_byte
end_col:   
            INC   COL_LO
            DEY
            BNE   write_col
end_cols:

            ; scroll camera, swap nametables to enable smooth wrap around scrolling
            INC   CAM_X
            BNE   done_wrap
wrap:
            LDA   NAMETABLE
            EOR   #$01
            STA   NAMETABLE
done_wrap:

            LDA   CAM_X       
            STA   PPUSCROLL
            LDA   #$00
            STA   PPUSCROLL

            ; turn on NMIs, set pattern table, set nametable
            LDA   #%10000000
            ORA   NAMETABLE
            STA   PPUCTRL

            ; toggle drawing of sprites, background, clipping etc.
            LDA   #%00011110
            STA   PPUMASK

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
            
            ; init nametables
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

            ; set defaults
            LDA   #$00
            STA   CAM_X
forever:    
            JMP   forever
.endproc

.include "helpers/load_screen.asm"
;     Scrolling Maps
;           1. DONE - Wraparound scrolling of two screens
;           2. Continuous scrolling of >2 screens
;                 Start writing columns offscreen etc. to implement scrolling > 2 screens
;                       a) DONE - every 16px scroll to the right write new tile(s) flag drawing a column
;                       b) implement drawing the column - write fake data
;                       c) " - write real data
;           3. Scroll to the right based on hero movement
;           4. Enable scrolling to the left
;           5. Scroll to the left based on hero movement
;           6. Stop scrolling at left-most and right-most ends of map

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