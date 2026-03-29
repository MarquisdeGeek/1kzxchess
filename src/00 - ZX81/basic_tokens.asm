
; Basic tokens
RND         equ $40
INKEYS      equ $41
PI          equ $42

DLBQUOTE    equ $C0  ; Quote inside quotes
AT          equ $C1
TAB         equ $C2

CODE        equ $C4
VAL         equ $C5
LEN         equ $C6
SIN         equ $C7
COS         equ $C8
TAN         equ $C9
ASN         equ $CA
ACS         equ $CB
ATN         equ $CC
LN          equ $CD
EXP         equ $CE
INT         equ $CF
SQR         equ $D0
SGN         equ $D1
ABS         equ $D2
PEEK        equ $D3
USR         equ $D4
STRS        equ $D5
CHRS        equ $D6
NOT         equ $D7
STAR_STAR   equ $D8
OR          equ $D9
AND         equ $DA
LEQ         equ $DB
GEQ         equ $DC
NEQ         equ $DD
THEN        equ $DE
TO          equ $DF
STEP        equ $E0
LPRINT      equ $E1
LLIST       equ $E2
STOP        equ $E3
SLOW        equ $E4
FAST        equ $E5
NEW         equ $E6
SCROLL      equ $E7
CONTINUE    equ $E8
CONT        equ $E8
DIM         equ $E9
REM         equ $EA
FOR         equ $EB
GO_TO       equ $EC
GO_SUB      equ $ED
INPUT       equ $EE
LOAD        equ $EF
LIST        equ $F0
LET         equ $F1
PAUSE       equ $F2
NEXT        equ $F3
POKE        equ $F4
PRINT       equ $F5
PLOT        equ $F6
RUN         equ $F7
SAVE        equ $F8
RANDOMIZE   equ $F9
RAND        equ $F9
IF          equ $FA
CLS         equ $FB
UNPLOT      equ $FC
CLEAR       equ $FD
RETURN      equ $FE
COPY        equ $FF


; Macro to define a line in the basic program.
; Usage, e.g.:
; 	BLINE 10, <PRINT, _QT, _H, _E, _L, _L, _O, _QT>
; Results in:
; 10 PRINT "HELLO"
	MACRO BLINE line_nr, tokens
		defb line_nr>>8, line_nr & $FF
		defw .end - .start
.start:
		defb tokens
		defb $76
.end
	ENDM


; The 2 macros BLINE_REM and BLINE_REM_END are used to define a REM line.
; Place our assember code between the 2 macros.
; Here is an example:
; 	BLINE_REM 1, rem_end
; 	nop ; your assembler instructions
; 	BLINE_REM_END
; rem_end:
	MACRO BLINE_START line_nr, tokens, end_address
		defb line_nr>>8, line_nr & $FF
		defw end_address - .start
.start:
		defb REM
	ENDM


	MACRO BLINE_END
		defb $76
	ENDM



    ; Macro that creates a BASIC sequence vor a number:
	; VAL "value"
	; I.e. the value is converted to decimal digits encoded
	; in ZX81 charset.
	; The number is surrounded by quates and the VAL token is added.
	; Can be used e.g. in a line like:
	; 20 RAND USR VAL "28881"
	MACRO VAL_NUMBER value
		defb VAL
		defb _QT
		defb value / 10000 + _0
		defb value / 1000 % 10 + _0
		defb value / 100 % 10 + _0
		defb value / 10 % 10 + _0
		defb value % 10 + _0
		defb _QT
	ENDM