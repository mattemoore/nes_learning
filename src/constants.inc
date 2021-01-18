; PPU Registers
PPUCTRL     =     $2000
PPUMASK     =     $2001
PPUSTATUS   =     $2002
PPUSCROLL   =     $2005
PPUADDR     =     $2006
PPUDATA     =     $2007
OAMADDR     =     $2003
OAMDMA      =     $4014

; NMI variables
CAM_X       =     $0100
NAMETABLE   =     $0101
DRAW_SEAM    =    $0102     
COL_HIGH    =     $0103
COL_LO      =     $0104
CURR_SCRN   =     $0105
COLS_REM    =     $0106       ;could be refactored to use zero-page or variable?
BYTES_IN_COL=     $0107       ;could be refactored to use zero-page or variable?

; 16 bytes of pointers (0110 - 011F) to screens making up current level
SCRN_MEM    =     $0110
CURR_SCRN_MEM =   $0120       ; 2 bytes representing mem location of current scrn