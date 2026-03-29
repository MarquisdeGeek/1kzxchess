; ZX81 BASIC Wrapper. (from https://github.com/maziac/zx81-sample-program)


	DEVICE NOSLOT64K
	SLDOPT COMMENT WPMEM, LOGPOINT, ASSERTION

	; Include character codes and BASIC tokens
	include "../00 - ZX81/charcodes.asm"
	include "../00 - ZX81/basic_tokens.asm"


; System variables tht start at $4009
	ORG $4009
VERSN:          defb 0
E_PPC:          defw 1
D_FILE:         defw DFILE_DATA		; $400C
DF_CC:          defw DFILE_DATA+1
VARS:           defw BASIC_VARS
DEST:           defw 0
E_LINE:         defw BASIC_END
CH_ADD:         defw BASIC_END+4
X_PTR:          defw 0
STKBOT:         defw BASIC_END+5
STKEND:         defw BASIC_END+5
BREG:           defb 0
MEM:            defw 0; was MEMBOT
UNUSED1:        defb 0
DF_SZ:          defb 2
S_TOP:          defw $0002
LAST_K:         defw $FDBF
DEBOUN:         defb 15
MARGIN:         defb 55
NXTLIN:         defw BASIC_PROGRAM	; Basic program next executed line
OLDPPC:         defw 0
FLAGX:          defb 0
STRLEN:         defw 0
T_ADDR:         defw $0C8D
SEED:           defw 0
FRAMES:         defw $F5A3
COORDS:         defw 0
PR_CC:          defb $BC
S_POSN:         defw $1821
CDFLAG:         defb $40

	; chess tramples over some of the system variables
	; so we replace PRBUFF and MEMBOT with our own data
	include "vars.asm"

	; Keep orgs to remind us of our alternate memory map
	org 16509
BASIC_PROGRAM:
	; 1 REM ... machine code ...
	BLINE_START 1, REM, rem_end
	include "1kchess.asm"
	BLINE_END
rem_end

	BLINE 2, <SLOW>
	BLINE 3, <RAND, USR, _X>

	org $4332
; Screen:
DFILE_DATA:
	; Blank lines at top
	defb $76, $76, $76, $76, $76
	; DRH line
	defb $80, $08, $a9, $b7, $ad, $76
	; Board
	defb $1d, $08, $37, $33, $27, $30, $36, $27, $33, $37, $76
	defb $1e, $08, $35, $35, $35, $35, $80, $35, $35, $35, $76 
	defb $1f, $08, $00, $80, $00, $80, $35, $80, $00, $80, $76 
	defb $20, $08, $80, $00, $80, $00, $80, $00, $80, $00, $76
	defb $21, $08, $00, $80, $00, $80, $00, $80, $00, $80, $76 
	defb $22, $08, $80, $00, $80, $00, $80, $00, $80, $00, $76
	defb $23, $08, $b5, $b5, $b5, $b5, $b5, $b5, $b5, $b5, $76
	defb $24, $08, $b7, $b3, $a7, $b0, $b6, $a7, $b3, $b7, $76
	; key
	defb $08, $08, $2d, $2c, $2b, $2a, $29, $28, $27, $26, $76
	; user input area
	defb $08, $08, $08, $08, $08, $76
	; blank end
	defb $76, $76, $76, $76, $76, $76, $76, $76

; BASIC variables:
BASIC_VARS:
	; X = 16959 : 7d  8f 04 7e 00 00 
	defb $7d
	defb 0x8F, 0x04, 0x7E, 0x00, 0x00
.end:
	defb $80

BASIC_END

