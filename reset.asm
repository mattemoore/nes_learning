.include "constants.inc"

.segment "CODE"
.import main
.export reset_handler
.proc reset_handler                       ; startup/reset button interrupt
            SEI                           ; ignore interrupts
            CLD

            LDX #$00                      ; disable rendering during startup
            STX PPUCTRL
            STX PPUMASK

vblankwait: BIT PPUSTATUS                 ; wait until PPU ready
            BPL vblankwait
            JMP main
.endproc