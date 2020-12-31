;Fickle.s - the source file which combines the bits from the first building
;phase and describes the resulting binary.
;(C)2011,2012 Malcolm Tyrrell (Malcolm.R.Tyrrell@gmail.com)

.include "Common.s"

.export decrunch_table
.export get_crunched_byte

.import decrunch

;********************************************************************
; INITIALIZATION
;********************************************************************

	;This area is used for the screen after initialization.
	.segment "CODE"
basicStub:
	;Header
        .word $1001		;Load address
	;BASIC stub
	.word @nextLine
	.word $0000		;Line number
	.byte $9E		;BASIC SYS token
	.byte .LOBYTE(((initialize / 1000) .mod 10) + $30)
	.byte .LOBYTE(((initialize / 100) .mod 10) + $30)
	.byte .LOBYTE(((initialize / 10) .mod 10) + $30)
	.byte .LOBYTE(((initialize / 1) .mod 10) + $30)
	.byte $00		;End of BASIC line
@nextLine:
	.word $0000		;End of BASIC marker

get_crunched_byte:
        LDA _byte_lo
        BNE @byte_skip_hi
        DEC _byte_hi
@byte_skip_hi:
        DEC _byte_lo
_byte_lo = * + 1
_byte_hi = * + 2
        LDA end_of_low_exo	; initialized to decrunch low.
        RTS

initialize:
	;Disable interrupts, because we'll be writing over system memory
	;and changing the interrupt vectors.
	SEI

	;Decrunch low.exo
        JSR decrunch

	;prepare the decruncher for decrunching main.
	;The pointers are only out by 2 after low has finished compressing.
	.assert .LOBYTE(end_of_main_exo) > 1, error, "Need to modify hi-byte too"
        ;LDA #.HIBYTE(end_of_main_exo)
        ;STA _byte_hi
        LDA #.LOBYTE(end_of_main_exo)
        STA _byte_lo
	;Make the decruncher "return" directly to the main initialization
	;location.
	LDA #.HIBYTE(initializeFickle)
	PHA
	LDA #.LOBYTE(initializeFickle) - 1
	PHA

	;fall through into decrunch.

	;linker puts decruncher here.

;*****************************************************************************
;* COMPRESSED DATA
;*****************************************************************************

	.segment "COMPRESSED_DATA"
start_of_main_exo:
	.incbin "main.exo"
end_of_main_exo:
	.incbin "low.exo"
end_of_low_exo:

;*****************************************************************************
;* OTHER MEMORY AREAS
;*****************************************************************************

	;This picks up the start location from the Phase2 linker script.
	.segment "INITIALIZEFICKLE"
initializeFickle:
	.assert * = $1000 + $190 + (12 * 8) + (NUM_CHARS * 8), error, "update linker script to handle change in NUM_CHAR"

	.segment "DECRUNCHTABLE"
decrunch_table:

