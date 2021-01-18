.include "constants.inc"
.include "header.inc"
.include "nmi.asm"                        ; all in-game writing to video ram must be done in here
.include "reset.asm"                      ; reset button code
.include "irq.asm"                        ; sound/catridge interrupt code
.include "init.asm"                       ; initial setup during start of game loop (pre-nmi start)

.segment "CODE"                           ; PRG-ROM

.export main                              ; make main referrable
.proc main
      
            JSR   init                    ; run pre-nmi init code
            
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
            JMP   set_seam_screen
      set_seam_name0:
            LDA   #$20
            STA   COL_HIGH
      set_seam_screen:                    ; store current screen's address
            LDA   CURR_SCRN              
            ASL   A                      
            TAX
            LDA   SCRN_MEM,X
            STA   CURR_SCRN_MEM
            INX
            LDA   SCRN_MEM,X
            STA   CURR_SCRN_MEM+1
end_seam:
            ; TODO: abstract seam writing to general writing (i.e. write to multi-purpose buffer in RAM...only write that in NMI)
            ; TODO: wait for NMI to be finished then loop
            JMP   forever
.endproc

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