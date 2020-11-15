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
            LDA   #$00                    ; tell the ppu there is no background scrolling
            STA   PPUSCROLL
            STA   PPUSCROLL
            RTI
.endproc

.import reset_handler                     ; imported reset handler
.import copy_1024

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
            LDX   PPUSTATUS                           ; prep PPU for writing
            LDX   #$20                                ; store PPU write address ($2000 is start of nametable 0)
            STX   PPUADDR
            LDX   #$00                    
            STX   PPUADDR
            
            ; store address of screen data ($8130)
            screenPtr = $0000
            LDA   #<screen1                          
            STA   screenPtr              ;30  
            LDA   #>screen1 
            STA   screenPtr+1            ;81

            ; 4 pages of 256 bytes = 1024 bytes to write
            pageCtr = $0002
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

vblankwait: BIT   PPUSTATUS
            BPL   vblankwait
vblankwait2:BIT   PPUSTATUS
            BPL   vblankwait2
            LDA   #%10000000              ; turn on NMIs
            STA   PPUCTRL

            JSR   copy_1024

forever:    JMP   forever
.endproc

; TODO: input and hero movement
; TODO: background scrolling 2 nametables
; TODO: background scrolling >2 namteables

.segment "VECTORS"                        ; specify interrupt handlers
.addr nmi_handler, reset_handler, irq_handler

.segment "CHR"                            ; CHR-ROM
.incbin "graphics.chr"

.segment "RODATA"
pallettes:                   
.include "pallettes.asm"

sprites:
.byte $07, $03, $00, $00
.byte $10, $04, $01, $10
.byte $20, $07, $02, $20
.byte $30, $08, $03, $30

.include "screen1.asm"
.include "screen2.asm"

.segment "STARTUP"