.segment "CODE"
.export reset_handler
.proc reset_handler                       ; startup/reset button interrupt
            SEI                           ; ignore interrupts
            CLD

            LDX #$00                      ; disable rendering during startup
            STX PPUCTRL
            STX PPUMASK

            JMP main
.endproc