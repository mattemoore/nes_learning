.segment "CODE"
.export load_screen
; X = Lobyte of address of screen to load
; Y = Hibyte of address of screen to load
; A = 0 to write to nametable0, anything else will write to nametable 1

.proc load_screen 
            ; store address of screen data
            screenPtr = $00
            STX  screenPtr              
            STY  screenPtr+1           

            ; determine which nametable to write to
            CMP   #$00
            BEQ   set_name0
            LDA   #$24
            JMP   write_name
set_name0:  
            LDA   #$20

write_name:
            LDX   PPUSTATUS                           ; prep PPU for writing
            TAX                                       ; store PPU write address
            STX   PPUADDR
            LDX   #$00                    
            STX   PPUADDR
            
            ; 4 pages of 256 bytes = 1024 bytes to write
            pageCtr = $02
            LDA #$04
            STA pageCtr

            ; while pages remain, loop through each byte of current page...
            LDY   #$00
load_back:  LDA   (screenPtr),Y           ; read current byte
            STA   PPUDATA                 ; write current byte
            INY   
            BNE   load_back               ; move to next byte

            DEC   pageCtr                 ; finished page, one less to go
            BEQ   done_load               ; done all pages, exit

            INC   screenPtr+1             ; move start byte to next page
            BNE   load_back               ; start processing next page
done_load:  
            RTS
.endproc
