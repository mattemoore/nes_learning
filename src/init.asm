; write palletes to PPU
            LDX   PPUSTATUS               ; prep PPU for writing
            LDX   #$3F                    ; store PPU write address ($3F00 is start of pallette memory)
            STX   PPUADDR
            LDX   #$00                    
            STX   PPUADDR
            LDX   #$00
load_plts:  
            LDA   pallettes,X
            STA   PPUDATA
            INX
            CPX   #$20
            BNE   load_plts

            ; write sprites to OAM buffer
            LDX   #$00
load_sprts: 
            LDA   sprites,X               
            STA   $0200,X
            INX
            CPX   #$10
            BNE   load_sprts

            LDX   #<screen1
            LDY   #>screen1
            LDA   #$00
            JSR   load_screen             ; write 1st screen of 1st level into nametable0

            ; set defaults
            LDA   #$00
            STA   CAM_X
            LDA   #$01
            STA   CURR_SCRN

            LDA   #<screen1               ; load 1st level screen mem locations 
            STA   SCRN_MEM
            LDA   #>screen1
            STA   SCRN_MEM+1

            LDA   #<screen2
            STA   SCRN_MEM+2
            LDA   #>screen2
            STA   SCRN_MEM+3

            LDA   #<screen3
            STA   SCRN_MEM+4
            LDA   #>screen3
            STA   SCRN_MEM+5

            LDA   #<screen4
            STA   SCRN_MEM+6
            LDA   #>screen4
            STA   SCRN_MEM+7

vblankwait: 
            BIT   PPUSTATUS
            BPL   vblankwait
vblankwait2:
            BIT   PPUSTATUS
            BPL   vblankwait2
            LDA   #%10000000              ; turn on NMIs when PPU is ready
            STA   PPUCTRL