; Utility functions/macros.

; Macros to define an expanded dfile screen.


; Macro to define a left aligned line in the dfile.
; Takes the ascii string and converts it to the ZX81 charset.
; asserts that the length of the string is <= 32.
; The string is padded with spaces to 32 characters.
; At the end a newline is appended.
	MACRO DLINEL ascii
.start
		defb ascii
.end
		assert .end - .start <= 32, Line exceeds 32 characters
		dup 32 - (.end - .start)
			defb 0
		edup
		defb $76	; Newline
	ENDM

; Like DLINEL but centers the line.
	MACRO DLINEC ascii
		; Get the length of ascii
		DEFARRAY tmparray ascii
.length equ tmparray[#]
		UNDEFINE tmparray
		assert .length <= 32, Line exceeds 32 characters
.start
		; Left spaces
		dup (32 - .length) / 2
			defb 0
		edup
		; Centered string
		defb ascii
		; Right spaces
		dup 32 - ($ - .start)
			defb 0
		edup
		defb $76	; Newline
	ENDM


; Macro to create one or more empty (expanded) lines.
; count = number of empty lines to create.
	MACRO DLINE_EMPTY count
		dup count
			dup 32
				defb 0
			edup
			defb $76	; Newline
		edup
	ENDM

; Fills the remianing lines.
	MACRO DLINE_FILL_REMAINING
.rem_lines: equ ($ - DFILE_DATA - 1) / 33
		;DISPLAY ".rem_lines=", /D, .rem_lines
		DLINE_EMPTY .rem_lines
	ENDM
