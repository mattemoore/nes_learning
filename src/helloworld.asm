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
            RTI
.endproc

.import reset_handler                     ; imported reset handler

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

            ; write nametable 0 (background)
            LDX   PPUSTATUS               ; prep PPU for writing
            LDX   #$20                    ; store PPU write address ($2000 is start of nametable 0)
            STX   PPUADDR
            LDX   #$00                    
            STX   PPUADDR


            ; 4 pages x 256 = 1024 bytes written
            pageCtr = $04
            
            ; store address of screen
            LDA   #<screen1 
            STA   $00                                 ;81
            LDA   #>screen1                          
            STA   $01                                 ;30               

            ; while pages remain, loop through each byte of current page...
            LDY   $0
load_back:  LDA   ($00),Y                             ; read a byte
            STA   PPUDATA                             ; write a byte
            INY   
            BNE   load_back                           ; next byte

            DEC   pageCtr                             ; finished page, one less to go
            BEQ   done_load                           ; done all pages, exit
            ; TODO : fix the loop up

            INC   screen1ptr+1                        ; next page;
            BNE   load_back                           ; more pages remaining;
done_load:  

vblankwait: BIT   PPUSTATUS
            BPL   vblankwait
            LDA   #%10010000              ; turn on NMIs, sprites use first pattern table
            STA   PPUCTRL
            LDA   #%00011110              ; render background
            STA   PPUMASK

forever:    JMP   forever
.endproc

; TODO: static background
; TODO: input and hero movement
; TODO: background scrolling

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
.byte $11, $02, $02, $02
sprites:
.byte $07, $03, $00, $00
.byte $10, $04, $01, $10
.byte $20, $07, $02, $20
.byte $30, $08, $03, $30

.include "screen1.asm"

.segment "STARTUP"