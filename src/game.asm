.include "constants.inc"
.include "header.inc"

.segment "CODE"                           ; PRG-ROM
.proc irq_handler                         ; sound/catridge interrupt
            RTI
.endproc

.proc nmi_handler
            ; TODO: push registers on stack

            ; transfer a page of OAM (sprite) buffer ($0200-$02FF) into PPU
            LDA   #$00  
            STA   OAMADDR
            LDA   #$02
            STA   OAMDMA

            LDA   DRAW_SEAM               
            CMP   #$01
            BNE   end_cols
draw_seam:
            LDA   #$02                    ; write two columns of 8x8 tiles
            STA   COLS_REM

            screenPtr = $00               ; put mem location of current screen data in zero page
            LDA   CURR_SCRN               ; TODO: Optimize this and put this in game logic
            ASL   A                      
            TAX
            LDA   SCRN_MEM,X
            STA   screenPtr
            INX
            LDA   SCRN_MEM,X
            STA   screenPtr+1
            STA   screenPtr+2             ; HACK: save copy of original hi byte of screen data address
            
write_col:                     
            LDA   #%00000100              ; prep PPU nametable mem location for writing           
            STA   PPUCTRL
            LDA   PPUSTATUS
            LDX   COL_HIGH                
            STX   PPUADDR
            LDX   COL_LO
            STX   PPUADDR

            LDY   COL_LO                  ; move COL_LO columns to the right from start of screen memory 
            LDA   #$1E                    ; one column is 30 bytes tall
            STA   BYTES_IN_COL
write_byte:                         
            LDA   (screenPtr),Y      
            STA   PPUDATA
            
            TYA                          ; increase Y by one row which is 32 bytes wide
            ADC   #$20                    
            TAY   

            BCC   next_byte              ; Y did not roll over so move to directly to next byte
            INC   screenPtr+1            ; Y rolled over so increase hi byte of mem location by one
            CLC                          ; clear carry flag so Y is not increased by an extra 1 next time
next_byte: 
            DEC   BYTES_IN_COL
            BNE   write_byte
end_col:   
            LDX   screenPtr+2             ; reset hi byte of screen data pointer
            STX   screenPtr+1
            INC   COL_LO
            DEC   COLS_REM
            BNE   write_col
end_cols:

            ; scroll camera, swap nametables to enable smooth wrap around scrolling
            INC   CAM_X
            BNE   done_wrap
wrap:
            INC   CURR_SCRN
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

            ; TODO: pop registers off stack
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

.include "init.asm"
            
forever:    
           
load_seam:    
      set_seam_flag:  
            LDA   #$00
            STA   DRAW_SEAM                    
            LDA   CAM_X
            AND   #%00001111              
            BNE   end_seam
            LDA   #$01
            STA   DRAW_SEAM               ; DRAW_SEAM flag set if scrolled 16px 

      set_col_num:
            LDA   CAM_X                   
            LSR   A
            LSR   A
            LSR   A 
            STA   COL_LO                  ; COL_LO = idx of first 8px column to draw

      set_seam_nametable:
            LDA   NAMETABLE               
            EOR   #$01
            CMP   #$00
            BEQ   set_seam_name0
            LDA   #$24
            STA   COL_HIGH                ; COL_HIGH = high byte of target nametable address
            JMP   end_seam
      set_seam_name0:
            LDA   #$20
            STA   COL_HIGH

      ; TODO: write data to buffer here then only write from buffer in NMI to min cycles in NMI
end_seam:
            
            JMP   forever
.endproc

.include "helpers/load_screen.asm"
;     Scrolling Maps
;           1. DONE - Wraparound scrolling of two screens
;           2. Continuous scrolling of >2 screens
;                 Start writing columns offscreen etc. to implement scrolling > 2 screens
;                       a) DONE - every 16px scroll to the right write new tile(s) flag drawing a column
;                       b) DONE - implement drawing the column - write fake data
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
.include "screen3.asm"
.include "screen4.asm"