.segment "CODE"
.export irq_handler
.proc irq_handler                         ; sound/catridge interrupt
            RTI
.endproc