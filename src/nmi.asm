.segment "CODE"
.export nmi_handler
.proc nmi_handler
            PHA                           ; back up registers (important)
            TXA
            PHA
            TYA
            PHA
            
            LDA   #$00                    ; transfer a page of OAM (sprite) buffer ($0200-$02FF) into PPU
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
            LDA   CURR_SCRN_MEM
            STA   screenPtr
            LDA   CURR_SCRN_MEM+1
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
            ; TODO write attribute tables so background tile colors are correct


            ; scroll camera, swap nametables to enable smooth wrap around scrolling
            INC   CAM_X                   ; TODO: update CAM_X in game loop
            BNE   done_wrap
wrap:
            INC   CURR_SCRN               ; TODO: move wrap logic to game loop
            LDA   NAMETABLE
            EOR   #$01
            STA   NAMETABLE
done_wrap:
            LDA   CAM_X                   ; TODO: only set cpu scroll if CAM_X changed or 
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

            PLA            ; restore regs and exit
            TAY
            PLA
            TAX
            PLA

            RTI
.endproc