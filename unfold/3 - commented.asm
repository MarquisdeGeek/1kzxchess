
; our SCORE routine stores its data here
SCORE_SCRATCHPAD:
    403c: defb 0 ; score of this move
    403d: defb 0 ; LSB of source square (D)
    403e: defb 0 ; LSB of destination square (E)
    403f: defb 0 ; Unused?? (C)
SCORE_SCRATCHPAD_END:
    4040: defb 0 ; Character code of the moved piece (B)


; when a better move is detected, it bulk copies the above 5 bytes into these 5
BEST_MOVE_DETAILS:
    4041: defb 0 ; best score
    4042: defb 0 ; LSB of source square (D)
    4043: defb 0 ; LSB of destination square (E)
    4044: defb 0 ; Unused?? (C)
    4045: defb 0 ; Character code of the moved piece (B)


MOVE_LIST:
A_4046:
    defb 0 ; count of items in list
A_4047:     ; first possible move
    dup $1C ; 28 possible moves
        defb 0
    edup

    405d: ; Technically belongs to BASIC ROM. Sys var MEMBOT, calculator area[0]
    4062: end of MOVE_LIST's $1C elements
MOVE_LIST_BACKUP:
    4063: ; Backup for MOVE_LIST (in the SHIFT routine). $1c bytes. 28 = not enough space in all cases!?!?!
    407b: ; Unused BASIC var[0]
    407E: ; final byte of saved MOVE_LIST

    407f: ; end of the move list data

ATTACK_REGISTER:
    4080: defw 0 ; attack square, e.g. location of human players king


TKP:
/**
The subroutine TKP just scans the keyboard waiting for an appropriate key to be depressed. The alpha-
numeric entry is then translated to a board address.

 * @param B (register) Holds 8, the number of allowed options
 * @param C (register) Holds the character code (either $1D or $26) of the first allowed option
 * @return (HL) (memory) The character code of the entered key
*/
    4082 : e5          PUSH hl      
TKP_NOT_FOUND:
    4083 : c5          PUSH bc      

TKP_LOOP:
    4084 : cd bb 02    CALL (ROM_KEYBOARD)
    ; ROM_KEYBOARD returns the key in HL, as row and mask
    4087 : 44          LD b,h        ; DECODE needs value in BC, so copy from HL
    4088 : 4d          LD c,l        
    4089 : 55          LD d,l        
    408a : 14          INC d        
    408b : 28 f7       JR z,(TKP_LOOP)  ; i.e. no keys are pressed, because mask was $ff and INCremented to 0
    408d : cd bd 07    CALL (ROM_DECODE)
    4090 : 7e          LD a,(HL)     ; A now has key code, write to screen
    4091 : c1          POP bc        
    4092 : c5          PUSH bc      
TKP_RETRY:
    4093 : b9          CP A,c        ; is it the current allowed character?
    4094 : 28 06       JR z,(TKP_FOUND)
    4096 : 0c          INC c        
    4097 : 10 fa       DJNZ (TKP_RETRY)
    ; All 8 tried, and failed
    4099 : c1          POP bc        
    409a : 18 e7       JR (TKP_NOT_FOUND)  
TKP_FOUND:
    409c : c1          POP bc        
    409d : e1          POP hl        
    409e : 77          LD (HL),a    
    409f : c9          RET          

KYBD:
/**
KYBD is a routine which sets up machine control of the keyboard such that only the eight key
codes from code 29 and the eight key codes from code 38 are acceptable entries. Any other
key depression is ignored.

29 ($1D) = 1
38 ($26) = A

For return codes:
@see STR
*/
    ; Get a number, 1-8
    40a0 : 01 1d 08    LD bc,081dH  ; prepare TKP to accept any 8 characters from $1D onwards (i.e. digits)
    40a3 : cd 82 40    CALL (TKP)  
    40a6 : 2b          DEC hl        ; screen memory to store and show square, reposition HL so TKP can store the letter
    ; Get a letter, A-H
    40a7 : 0e 26       LD c,26H      ; since B is set, now accept characters from $26 onwards
    40a9 : cd 82 40    CALL (TKP)  
    40ac : 23          INC hl        
    40ad : 7e          LD a,(HL)     ; get the numbered row, again
    40ae : d6 1c       SUB 1cH       ; converts A from key code to number 1-8
    40b0 : 47          LD b,a        
    40b1 : 0e 0b       LD c,0bH      ; our loop multiplies this number by 11 (characters in row), result in A, through successive addition by KYBD_LOOP
    40b3 : af          XOR A,a       ; sneaky A=0
KYBD_LOOP:
    40b4 : 81          ADD A,c      
    40b5 : 10 fd       DJNZ (KYBD_LOOP)

    40b7 : c6 61       ADD A,61H     ; offset to board
    40b9 : 2b          DEC hl        ; return to point HL at the column letter (which holds a character code)
    40ba : 96          SUB A,(HL)   ; move along lettered columns. Because (HL) is a character code, 'A' ia $26
    ; fall through to STR


STR:
/**
STR: this routine takes the board address and determines whether the contents
are: 

0 = different from the current mover colour
1 = empty
2 = the board surround
3 = the same colour as the current mover

 * @param A (register) the LSB address of the square in question (MSB of screen is $43)

 * @return A & B (register) one of the four values above
 * @return L (register) the LSB address of the square in question (MSB of screen is $43)
*/
    40bb : 4f          LD c,a        
    40bc : 69          LD l,c        
    40bd : 26 43       LD h,43H      
STR_FROM_HL:
    ; Get piece (from screen memory) at the position
    40bf : 7e          LD a,(HL)    
    40c0 : 06 01       LD b,01H      
    ; THis mask clears the MSB, effectively ignoring the piece colour
    40c2 : e6 7f       AND 7fH      
    40c4 : fe 00       CP 00H        
    ; If a blank square, B=1, jump to found
    40c6 : 28 14       JR z,(STR_FOUND)
    40c8 : 04          INC b        
    ; If the right edge of board ($76=118=Halt), B=2, jump out
    40c9 : fe 76       CP 76H        
    40cb : 28 0f       JR z,(STR_FOUND)
    ; When A < 76H it's also an edge, B is still 2, jump out
    40cd : fe 27       CP 27H        
    40cf : 38 0b       JR c,(STR_FOUND)
    ; if piece is same colour
    40d1 : 7e          LD a,(HL)    
    40d2 : 04          INC b        
    40d3 : 2e 37       LD l,37H      
    40d5 : 86          ADD A,(HL)    
    40d6 : cb 7f       BIT 7,a      
    40d8 : 28 02       JR z,(STR_FOUND)
    ; else, must be same colour, return B=0
    40da : 06 00       LD b,00H      
STR_FOUND:
    40dc : 78          LD a,b        
    40dd : 69          LD l,c        
    40de : c9          RET          


; piece movements are done via these lookup tables
; (pawns have additional logic)
TABLES: ; these are in decimal
40df: ; 16607 = king movements
    defb 1, 11, -1, -11,  -10, -12, 12, 10
    ; 40e3 holds the bishop movements, as the final 4 items in the king list (-10,-12,12,10)
    ; 40e4 holds the black pawn movements (-11  -10 -12)

40e7: ;16615 = knight movements
    defb 13, -13, 21, -21, 23, -23, -9, 9

40ef: ; 16623 = white pawn
    defb 11, 10, 12

40f2: ;16626 Character codes for the pieces - QRNBP - in order, for PSC to score them
    defb 54, 55, 39, 51, 53

 

PIECE:
/**
Piece: this sets up pointers to possible move tables, and number of steps and directions.

Falls through to MOVE

 * @param E (register) LSB of the memory address of the source location (not touched here, but used in MOVE)
 * @param HL (register) screen location of piece to consider 
*/
    40f7 : af          XOR A,a      
    40f8 : 32 46 40    LD (MOVE_LIST),A  ; reset the count of possible moves to 0
    40fb : 7e          LD a,(HL)    
    40fc : e6 7f       AND 7fH       ; mask off colour
    40fe : fe 35       CP 35H        ; is it a pawn? if so use the special logic
    4100 : 28 4f       JR z,(PAWN)

    ; HL = ptr to table of permitted directions
    ; B = number of directions in the table
    ; C = number of times that direction may be moved (so king would have C=1, and queen C=8, using the same table)
    4102 : 0e 01       LD c,01H      
    4104 : 06 08       LD b,08H      
    4106 : 21 e7 40    LD hl,40e7H   ; a table of knight moves
    4109 : fe 33       CP 33H        ; is it a knight?
    410b : 28 16       JR z,(MOVE)

    410d : 2e df       LD l,dfH      ; because H is already set to 40e7 above, we only change L, so HL=40df
    410f : fe 30       CP 30H        ; is it the king?
    4111 : 28 10       JR z,(MOVE)

    4113 : 48          LD c,b        ; c=b=8. Note that the order allows us to use a one byte LD c,b instead of LD C,8H
    4114 : fe 36       CP 36H        ; is it the queen?
    4116 : 28 0b       JR z,(MOVE)

    4118 : 06 04       LD b,04H      
    411a : fe 37       CP 37H        ; is it a rook?
    411c : 28 05       JR z,(MOVE)

    411e : 2e e3       LD l,e3H      ; H is still 40, so now HL=40e3 which are the diagonal movements of the king
    4120 : fe 27       CP 27H        ; is it a bishop? if not, RETurn
    4122 : c0          RET nz        ; Z80 has these nice 'if flags, then return' to save JR z, followed by another JR

    ; having setup up B,C, and HL, fall through to MOVE

MOVE:
/**
Move produces a list of all legal moves available to the piece under consideration. It places
them in the MOVE_LIST.
(Note that the move list has already been cleared by PIECE)

This happens after player selects source location, even if this routine were slow
(which it really isn't) then I'd compute the list here, since any delay would be
covered by the time it takes a human to press their next key.

 * @param HL (register) ptr to table of permitted directions (determined from above PIECE routine)
 * @param B (register) number of directions in the table (determined from above PIECE routine)
 * @param C (register) number of times that direction may be moved (determined from above PIECE routine)
 * @param E (register) LSB of the memory address of the source location
 
*/
MOVE_NEXT_DIRECTION:
    4123 : 7b          LD a,e        ; reset A to the source position
MOVE_CONTINUE_ON_PATH:
    4124 : 86          ADD A,(HL)    ; add offset from table and determine new square, stored into A
    4125 : f5          PUSH af      
    4126 : e5          PUSH hl      
    4127 : c5          PUSH bc      
    4128 : fe 3f       CP 3fH        ; if A < $3F, i.e. off board (top), since H1 is $433F
    412a : 38 1e       JR c,(MOVE_INVALID)

    412c : fe 94       CP 94H        
    412e : 30 1a       JR nc,(MOVE_INVALID) ; if A >=$94, i.e. off board (bottom)

    4130 : cd bb 40    CALL (STR)  
    4133 : fe 02       CP 02H        ; is target is 2 (wall) or 3 (same colour), consider invalid
    4135 : 30 13       JR nc,(MOVE_INVALID)

    4137 : f5          PUSH af      
    4138 : cd 8d 42    CALL (ALIST)  
    413b : f1          POP af        

    413c : fe 00       CP 00H        ; capture??
    413e : 28 0a       JR z,(MOVE_MADE_SO_CONTINUE)
    4140 : c1          POP bc        
    4141 : e1          POP hl        
    4142 : 79          LD a,c        ; Can the piece move more spaces in this direction?
    4143 : fe 01       CP 01H        ; (by checking if A==1, i.e. empty)
    4145 : 28 05       JR z,(MOVE_ON_NEXT_DIRECTION) ; No - so end now, and move onto next dir

    4147 : f1          POP af        ; recover a, holding new start position (i.e. origial A + (HL))
    4148 : 18 da       JR (MOVE_CONTINUE_ON_PATH) ; attempt to continue moving this the same direction  
MOVE_INVALID:
MOVE_MADE_SO_CONTINUE:
    414a : c1          POP bc        
    414b : e1          POP hl        
MOVE_ON_NEXT_DIRECTION:
    414c : f1          POP af        
    414d : 23          INC hl        ; move to next entry in list
    414e : 10 d3       DJNZ (MOVE_NEXT_DIRECTION) ; REM: decrements B, and jumps if !=0
    4150 : c9          RET          


PAWN:
/**
Pawn produces a list of all possible legal moves including initial double moves.

 * @param HL (register) screen location of piece to consider 
*/
    4151 : 7e          LD a,(HL)     ; re-grab the piece 'P' into A
    4152 : e6 80       AND 80H       ; 80H for black, 0 for white
    4154 : 21 e4 40    LD hl,40e4H   ; HL to reference the 3 valid move offsets by borrowing from the king's movement, -11  -10 -12, point to last of these
    4157 : 20 02       JR nz,(PAWN_IS_BLACK)
    4159 : 2e f1       LD l,f1H      ; HL is now $40f1, the special pawn offsets (11 10 12) for white
PAWN_IS_BLACK:
    415b : 16 03       LD d,03H      ; D is our count of the 3 possible directions a pawn can move
PAWN_NEXT_DIRECTION:
    415d : 7b          LD a,e        
PAWN_NEXT_ALONG_DIRECTION:
    415e : 86          ADD A,(HL)    
    415f : e5          PUSH hl      
    4160 : f5          PUSH af      
    4161 : fe 3f       CP 3fH        ; if A<64 it's invalid because off the board
    4163 : 38 20       JR c,(PAWN_INVALID_MOVE)
    4165 : fe 94       CP 94H        ; if A>=148, it's also off board
    4167 : 30 1c       JR nc,(PAWN_INVALID_MOVE)

    4169 : cd bb 40    CALL (STR)    ; we're still considering our colour, at this point
    416c : fe 00       CP 00H        ; is piece on target square a different colour?
    416e : 28 1c       JR z,(PAWN_POSSIBLE_CAPTURE)

    4170 : fe 01       CP 01H        ; if anything but empty (i.e. wall or same colour), so invalid
    4172 : 20 11       JR nz,(PAWN_INVALID_MOVE)

    4174 : 7a          LD a,d        
    4175 : fe 01       CP 01H        ; moving -10 or -12 is only permitted in capture. If we're here, then we're not capturing, so fail
    4177 : 20 0c       JR nz,(PAWN_INVALID_MOVE)

    4179 : cd 8d 42    CALL (ALIST)  ; add to list
    417c : 7b          LD a,e        
    417d : fe 52       CP 52H        ; if A < $52 the pawn is in row 1 or 2, so might be able to move again
                                     ; this check happens for pawns of either colour. This is allowed because
                                     ; white pawns are never in row 1, and black pawns (if they reach row 2) have
                                     ; only one row left to move and so those moves are rejected as being off the
                                     ; top of the board
    417f : 38 13       JR c,(PAWN_MAY_MOVE_TWICE)
    4181 : fe 7e       CP 7eH        ; if A>= $7e the pawn is in row 7 or 8
    4183 : 30 0f       JR nc,(PAWN_MAY_MOVE_TWICE)

PAWN_INVALID_MOVE:
PAWN_CONTINUE_MOVE:
    4185 : f1          POP af        
    4186 : e1          POP hl        
    4187 : 2b          DEC hl        ; move to next possible move offset
    4188 : 15          DEC d         ; any more offets in the list?
    4189 : 20 d2       JR nz,(PAWN_NEXT_DIRECTION)
    418b : c9          RET          

PAWN_POSSIBLE_CAPTURE:
    418c : 7a          LD a,d        
    418d : fe 01       CP 01H        
    418f : c4 8d 42    CALL nz,ALIST  ; if the piece is anything but 1 (empty), then it's a capture
    4192 : 18 f1       JR (PAWN_CONTINUE_MOVE)

PAWN_MAY_MOVE_TWICE:
    4194 : f1          POP af        
    4195 : e1          POP hl        
    4196 : 5f          LD e,a        ; set the current position to be the first single space move
    4197 : 18 c5       JR (PAWN_NEXT_ALONG_DIRECTION)   ; we can then re-check for another single space move. (It helps that the single forward move is the last one checked)


SCORE:
/**
Score provides a move score based on the following:

1. the "To" position results in taking of a piece
2. the "From" position is attacked
3. the "To" position is attacked
4. "To" enables the computer to obtain a check
5. finally the "From" position is defended.

The current move score is then compared with the previous best and if this is superior,
the move is saved as the best so far.

 * @param A (register) character code of the captured piece, or 0
 * @param B (register) character code of the moved piece
 * @param HL (register) the address of the source square
 * @param DE (register) the address of the destination square

*/
    4199 : e5          PUSH hl       ; (pop at $41d2)
    419a : c5          PUSH bc       ; (pop at $41bc as DE)
    419b : d5          PUSH de       ; (pop at $41b7 as HL)
    419c : e5          PUSH hl       ; (pop at $41af)
    419d : c5          PUSH bc       ; (pop at $41ab as AF)
    419e : 55          LD d,l        ; backup the LSB of our source square, so it gets saved by ROM_COPY_REGISTERS
    419f : 21 40 40    LD hl,SCORE_SCRATCHPAD_END ; note that we write out values backwards  
    41a2 : cd 24 07    CALL (ROM_COPY_REGISTERS)  ; borrow a routine from ROM to write B, C, E, D (in that order) to the address of HL, HL-1, HL-2, and HL-3

    41a5 : cd 0a 43    CALL (PSC)  ; get a material score/value for the captured piece (held in A). Returned in B
    41a8 : 78          LD a,b        ; our initial score is the material value of our piece
    41a9 : 84          ADD A,h         ; we increment by $40 (the high byte of SCORE_SCRATCHPAD_END) to avoid negatives 
                                        ; later on. it also ensures that _any_ valid move scores some points, so 
                                        ; we can determine a checkout when the best move scores 0
    41aa : 4f          LD c,a        ; keep the score safe, in C
    41ab : f1          POP af        ; when we pushed BC it held B as the moved piece. that is now removed and placed in A

    41ac : cd 0a 43    CALL (PSC)    ; material value of the piece we moved
    41af : e1          POP hl        ; recover the source location

    41b0 : cd 18 43    CALL (INC_BEING_ATTACKED)  ; this indicates whether the _opposition_ is being attacked from HL
    41b3 : 30 01       JR nc,(SCORE_DONT_ADD) ; if _they_ weren't being attacked, don't increase the score
    41b5 : 80          ADD A,b      ; amend local score by value of piece
SCORE_DONT_ADD:
    41b6 : 4f          LD c,a        ; keep the score safe, in C
    41b7 : e1          POP hl        ; HL is now the destination square address (was DE upon entry)
    41b8 : d1          POP de        ; D=character code of piece moving (was B upon entry)
    41b9 : 5e          LD e,(HL)     ; get the character code of the piece in the destination square
    41ba : 72          LD (HL),d     ; move our piece into the target square, potentially capturing something
    41bb : e5          PUSH hl      
    41bc : d5          PUSH de      
    41bd : cd 18 43    CALL (INC_BEING_ATTACKED)  ; is the opposition being attacked from our new position?
    41c0 : 30 01       JR nc,(SCORE_DONT_SUB)   ; ??
    41c2 : 90          SUB A,b      
SCORE_DONT_SUB:
    41c3 : f5          PUSH af      
    41c4 : cd f7 42    CALL (CHGMV)  ; change sides so we can...
    41c7 : cd 01 42    CALL (CHK)    ; see if the human has been placed in check
    41ca : c1          POP bc        ; recovers the score into B 
    41cb : 30 02       JR nc,(SCORE_DONT_SCORE_FOR_CHECK) ; and if not in check, skip. i.e. if they are checked, continue and add 2 points
    41cd : 04          INC b        
    41ce : 04          INC b        
SCORE_DONT_SCORE_FOR_CHECK:
    41cf : d1          POP de        ; recover DE from $41bc (where D holds character code of moving piece, E is captured piece)
    41d0 : e1          POP hl        ; recover HL from $41bb (which holds address of destination square)
    41d1 : 73          LD (HL),e     ; replace capture piece back on board
    41d2 : e1          POP hl        ; recover HL from $4199 (source square)

    41d3 : cd fa 42    CALL (CHGMV_AT_HL)  ; toggle the white AI piece, in its source square, to be black
    41d6 : cd 18 43    CALL (INC_BEING_ATTACKED)  
    41d9 : 30 01       JR nc,(SCORE_DONT_SUB2) ; not being attacked
    41db : 05          DEC b        
SCORE_DONT_SUB2:
    41dc : cd fa 42    CALL (CHGMV_AT_HL)  ; toggle piece back to white
    41df : cd f7 42    CALL (CHGMV)     ; change player back to white

    ; Finally, compare this score with the best
    41e2 : 78          LD a,b        
    41e3 : 21 3c 40    LD hl,SCORE_SCRATCHPAD
    41e6 : 77          LD (HL),a        ; store the score for this move
    41e7 : eb          EX DE,HL      
    41e8 : 21 41 40    LD hl,BEST_MOVE_DETAILS      ; prepare to compare the existing best score (in HL)
    41eb : be          CP A,(HL)        ; if local score < best score, the carry flag set
    41ec : d8          RET c            ; so this RETurns if the score isn't as good
    ; new best score found
    41ed : 01 05 00    LD bc,0005H      ; prepare to copy 5 bytes from DE to HL
                                        ; DE = local, current, score
                                        ; HL = global, best score
    41f0 : 18 0b       JR (SHIFT_REVERSE_COPY)  ; the reverse ensures DE becomes HL, the actual source of the copy


SHIFT:
/**
Shift moves the current move list to a safe position whilst Check is being evaluated, and
then recovers the move list on completion. It is also used to shift the best move so far up into
the move list.

 * @param C (flag) if clear, copy move list _to_ the backup. If set, copy _from_ backup to list
*/
    41f2 : 21 63 40    LD hl,MOVE_LIST_BACKUP  ; source addr
    41f5 : 11 46 40    LD de,MOVE_LIST  ; dest addr
    41f8 : 01 1c 00    LD bc,1cH        ; copy only 28 bytes
    41fb : 38 01       JR c,(SHIFT_FROM_BACKUP) ; if carry flag is set skip over this, which...
SHIFT_REVERSE_COPY:
    41fd : eb          EX DE,HL      ; ...reverses direction of copy, from MOVE_LIST to BACKUP (e.g.)
SHIFT_FROM_BACKUP:
    41fe : ed b0       LDIR          ; copies bytes from consecutive address at HL, write into DE
    4200 : c9          RET          


CHK:
/**
CHECK locates current mover's Kings and stores the position in the attack register.

It then drops through to determine if that piece is being attacked.

 * @return C (flag) 1 = is in check, 0 = not in check
*/
    4201 : 3a 37 43    LD A,(4337H)  ; screen holding curent player. 128=black, 0=white
    4204 : c6 30       ADD A,30H     ; character for K, so A is now either a white K ($30), or black/inverse K ($B0)
    4206 : 21 3e 43    LD hl,433eH   ; grey square, immediately before H1 (white rook)
    4209 : 47          LD b,a        
    420a : ed b1       CPIR          ; searches by comparing A with all squares until it finds the king
    420c : 2b          DEC hl        ; since CPIR overshoots by 1 byte, this compensates
    420d : 22 80 40    LD (ATTACK_REGISTER),HL
    ; fall through

SQUARE_ATACK:
SQ_AT:
/**
Determines whether the opposition can attack the square in the attack register.

It loops through every opponent piece of the board, generating (and then checking) its MOVE_LIST to
see if the requested square is in that list.

 * @return L (register) source square which can attack us
 * @return C (flag) 1 = can attack square, 0 = can not attack square
*/
    4210 : 06 56       LD b,56H     ; there are 86 bytes which might have an opponent piece on (we worry about
                                    ; excluding the edges, as they don't have any character codes that would
                                    ; erroneously match a real piece)
    4212 : 21 3e 43    LD hl,433eH  ; the square immediately before the first
SQUARE_ATACK_NEXT_SQUARE_ON_BOARD:
    4215 : 23          INC hl        
    4216 : e5          PUSH hl      
    4217 : c5          PUSH bc      
    4218 : 5d          LD e,l        ; E now holds the LSB of the square's location, as it usually does
    4219 : cd bf 40    CALL (STR_FROM_HL)  ;  we have already set the position of the interesting square into HL, so jump part-way into the STR code
    421c : fe 00       CP 00H        
    421e : 20 19       JR nz,(SQUARE_ATACK_NOT_AN_OPPONENT_PIECE)

    4220 : cd f7 42    CALL (CHGMV)  ; consider from opponent's POV
    4223 : 6b          LD l,e        ; recover square of interest, since CHGMV destroys L
    4224 : cd f7 40    CALL (PIECE)  ; find all positions that this opponent's piece can move to
    4227 : cd f7 42    CALL (CHGMV)  ; switch POV back

    ; check move list
SQUARE_ATACK_NOT_FOUND:
    422a : cd 82 42    CALL (TEST_LIST) ; get the first/next possible move into A
    422d : 28 0a       JR z,(SQUARE_ATACK_NO_MOVES_LEFT)

    422f : 2a 80 40    LD HL,(ATTACK_REGISTER)
    4232 : bd          CP A,l        
    4233 : 20 f5       JR nz,(SQUARE_ATACK_NOT_FOUND)
    ; getting here means "found a piece that can attack"
    4235 : c1          POP bc        
    4236 : e1          POP hl        
    4237 : 37          SCF          ; set carry flag to indicate success, opposition can attack here
    4238 : c9          RET          

SQUARE_ATACK_NO_MOVES_LEFT:
SQUARE_ATACK_NOT_AN_OPPONENT_PIECE:
    4239 : c1          POP bc        
    423a : e1          POP hl        
    423b : 10 d8       DJNZ (SQUARE_ATACK_NEXT_SQUARE_ON_BOARD)
    423d : a7          AND A,a      ; also clears the flag flag
    423e : c9          RET          


DRIVER:
/**
Driver Main control logic, uses all the other subroutines to provide program control.
*/
    423f : 06 05       LD b,05H      ; 5 characters to write
    4241 : 3e 08       LD a,08H      ; the grey hash character
    4243 : 21 9f 43    LD hl,439fH   ; bottom row of the display, where the user enters the move
DRIVER_ERASE_INPUT_AREA_LOOP:
    4246 : 23          INC hl        
    4247 : 77          LD (HL),a    
    4248 : 10 fc       DJNZ (DRIVER_ERASE_INPUT_AREA_LOOP)

DRIVER_GET_INPUT:
    424a : cd a0 40    CALL (KYBD)    ; get the source location, returned in HL
    424d : fe 03       CP 03H        
    424f : 20 ee       JR nz,(DRIVER) ; If it's not same coloured piece as player (3) retry

    4251 : 22 07 40    LD (4007H),HL  ; HL holds the memory addr (in screen memory) of the piece to move
    4254 : 5d          LD e,l         ; now the E register holds the LSB of the piece position. This is (almost) never changed
    4255 : cd f7 40    CALL (PIECE)   ; get all possible moves for this piece

    4258 : 21 a1 43    LD hl,43a1H    ; prepare to write destination move into $43a1, which is screen memory
    425b : cd a0 40    CALL (KYBD)    ; get destination location, returned in HL

    425e : fe 02       CP 02H         ; 0,1 produce a carry. 2 and 3 don't
    4260 : eb          EX DE,HL       ; DE now holds dest, and HL holds source
    4261 : 30 dc       JR nc,(DRIVER) ; so if target is 2 or 3 (wall or same colour) we jump back to the start
    ; QQ. is the above necessary, if we have a list of valid moves?!?!?!

DRIVER_CHECK_NEXT_MOVE:
    4263 : cd 82 42    CALL (TEST_LIST)  
    4266 : 28 d7       JR z,(DRIVER) ; if no valid moves left, jump back to start to get new input move
    4268 : b9          CP A,c        ; if the square returned from TEST_LIST, in A, does not match the destination square the player entered (in C)...
    4269 : 20 f8       JR nz,(DRIVER_CHECK_NEXT_MOVE) ; ... try the next move in the list

    426b : cd ff 42    CALL (PMOVE)  ; move the player's piece (HL still holds the source square)

    426e : d9          EXX           ; save our registers, in case we need to revert the move
    426f : cd 01 42    CALL (CHK)  
    4272 : d9          EXX          
    4273 : 38 08       JR c,(DRIVER_HUMAN_MOVED_INTO_CHECK)

    ; AI's turn
    4275 : cd eb 42    CALL (42ebH)  
    4278 : cd 96 42    CALL (MPSCAN)

DRIVER_STEPPING_STONE:
    427b : 18 c2       JR (DRIVER)  

DRIVER_HUMAN_MOVED_INTO_CHECK:
    427d : 70          LD (HL),b    ; replace the human piece on the source square
    427e : 79          LD a,c       ; C still holds the captured piece from PMOVE
    427f : 12          LD (DE),A    ; replace the captured piece onto the destination square
    4280 : 18 f9       JR (DRIVER_STEPPING_STONE)  


TEST_LIST:
/*
TestList: tests to see if there are any moves in the move list.

 * @return (A) (register) 0 if no moves, otherwise destination location of the next valid move
*/
    4282 : 21 46 40    LD hl,MOVE_LIST  
    4285 : 35          DEC (HL)      ; pre-emptively decrement the size of the list by 1
    4286 : 7e          LD a,(HL)    
    4287 : 3c          INC a        
    4288 : c8          RET z         ; A=0 if nothing in list, return
    4289 : 85          ADD A,l       ; move A to point to last entry in list (A is the LSB at this point)
    428a : 6f          LD l,a        ; move A back into L, so the complete address is in HL
    428b : 7e          LD a,(HL)     ; return move at end of list, having already eliminated from list
    428c : c9          RET          


ALIST:
/*
This adds to the current legal move list by adding another entry on the end.

Essentially a stack,pushing new data to the end (at higher addresses), and removing from
the end (via TEST_LIST) later.

 * @param C (register) LSB of the destination location to be added
*/
    428d : 21 46 40    LD hl,MOVE_LIST
    4290 : 34          INC (HL)      ; inc the size of the list, which our first byte
    4291 : 7e          LD a,(HL)    
    4292 : 85          ADD A,l       ; move A to point to last entry in list (A is the LSB at this point)
    4293 : 6f          LD l,a        ; reconstruct HL so it points to next free entry. i.e. MOVE_LIST+count
    4294 : 71          LD (HL),c     ; store it
    4295 : c9          RET          


MPSCAN:
/**
MPScan scans the board for computer pieces and, using move and score, determines
all legal moves and saves the best.
*/
    4296 : af          XOR A,a      ; A=0, basically
    4297 : 32 41 40    LD (BEST_MOVE_DETAILS),A  ; Best move score is now 0
    429a : 06 56       LD b,56H      ; Like the code at $4210, we overscan the board, knowing that edge pieces get rejected early
    429c : 21 3e 43    LD hl,433eH   ; the square before H1, on top left
MPSCAN_NEXT_SQUARE:
    429f : 23          INC hl        
    42a0 : e5          PUSH hl      
    42a1 : c5          PUSH bc      
    42a2 : 5d          LD e,l        ; E holds the LSB of the source square, as usual
    42a3 : cd bf 40    CALL (STR_FROM_HL)  ; determine the contents of the current square
    42a6 : fe 03       CP 03H        
    42a8 : 20 29       JR nz,(MPSCAN_NOT_AI_PIECE)    ; if it's not an AI piece, then skip

    42aa : 6b          LD l,e        
    42ab : 22 07 40    LD (4007H),HL     ; make a note of the piece we plan to move
    42ae : cd f7 40    CALL (PIECE)      ; get all possible moves
MPSCAN_NEXT_MOVE_FROM_LIST:
    42b1 : cd 82 42    CALL (TEST_LIST)  ; because a piece will never be at address 0, we re-use a return of 0 meaning "did not found"
    42b4 : 28 1d       JR z,(MPSCAN_NOT_AI_PIECE)     ; and we jump if no moves in the list

    42b6 : 5f          LD e,a         ; A was filled by TEST_LIST to contain a suitable destination location. Put it in the usual E reg
    42b7 : 16 43       LD d,43H       ; The MSB of the screen, making DE a valid screen ptr.
    42b9 : cd ff 42    CALL (PMOVE)   ; Make the move, returned as HL to DE. On-screen it looks like the machine is thinking.
    42bc : d9          EXX          
    42bd : a7          AND A,a       ; this also clears carry flag, so that the SHIFT routine copies MOVE_LIST to a save store
    42be : cd f2 41    CALL (SHIFT)  ; save the current list of moves
    42c1 : cd 01 42    CALL (CHK)    ; did we put the human player in check? (result is in carry flag, but don't use it yet)
    42c4 : d9          EXX          
    42c5 : 70          LD (HL),b     ; return the piece (B) to it's original position
    42c6 : 79          LD a,c        ; (just like we do when the player moves into check at $427d)
    42c7 : 12          LD (DE),A     ; return captured piece, if any (A) - remembering that HL=source square, DE=destination
    42c8 : 38 03       JR c,(MPSCAN_RECOVER_MOVE_LIST) ; if we put them in check (carry flag set back in $42c1) then skip the SCORE computation

    42ca : cd 99 41    CALL (SCORE)  ; Knowing the move was valid, score it

MPSCAN_RECOVER_MOVE_LIST:
    42cd : 37          SCF           ; set carry flag, so that the SHIFT routine retrieve MOVE_LIST from the save store
    42ce : cd f2 41    CALL (SHIFT)  ; and do the retrieval, before continuing with the next move on the list
    42d1 : 18 de       JR (MPSCAN_NEXT_MOVE_FROM_LIST)  

MPSCAN_NOT_AI_PIECE:
    42d3 : c1          POP bc        
    42d4 : e1          POP hl        
    42d5 : 10 c8       DJNZ (MPSCAN_NEXT_SQUARE)

    ; once all squares have been considered...
    42d7 : 3a 41 40    LD A,(BEST_MOVE_DETAILS)  
    42da : fe 00       CP 00H        ; if there are no moves for the AI...
MPSCAN_HUMAN_WINS:
    42dc : 28 fe       JR z,(MPSCAN_HUMAN_WINS) ;... we spin in an endless loop

    42de : 21 45 40    LD hl,4045H  ; final byte of BEST_MOVE_DETAILS
    42e1 : 7e          LD a,(HL)    ; original B, character code of the piece to move
    42e2 : 2b          DEC hl        
    42e3 : 2b          DEC hl        
    42e4 : 5e          LD e,(HL)    ; original E from $4043, the LSB of the best destination square
    42e5 : 16 43       LD d,43H     ; fixed screen offset
    42e7 : 12          LD (DE),A    ; move the piece into the destination square
    42e8 : 2b          DEC hl        
    42e9 : 6e          LD l,(HL)    ; original D from $4042, holding the LSB for the source square
    42ea : 62          LD h,d       ; reconstruct HL to point to screen (saves a byte over LD d,43H)

    ; determine if the square we were on is white or black
    42eb : cb 45       BIT 0,l      ; test the bit, doing a "is it even" check. Z=1 if even
    42ed : 36 80       LD (HL),80H  ; write a black square
    42ef : 28 02       JR z,(MPSCAN_SQUARE_WAS_BLACK); but if it was even, skip the next bit..
    42f1 : 36 00       LD (HL),00H  ; ..to re-write as white
MPSCAN_SQUARE_WAS_BLACK:
    42f3 : cd f7 42    CALL (CHGMV)  ; switch back the human player here (not in the DRIVER loop, strangely!?!?!)
    42f6 : c9          RET          


/**
CHGMV, or change mover, toggle between the player and computer, from 0 to $80 and back

Note that the 'current player' variable is held on-screen as a white or black square.
*/
CHGMV:
    42f7 : 21 37 43    LD hl,4337H  ; the top left location on-screen
CHGMV_AT_HL:
    42fa : 7e          LD a,(HL)    ; either 0 or $80 if top left location, or toggle MSB in general
    42fb : c6 80       ADD A,80H    ; rely on overflow to transition from $80 to 0
    42fd : 77          LD (HL),a    ; write back
    42fe : c9          RET          


/**
PMOVE moves a piece

 * @param 4007H (memory) source square
 * @param DE (register) destination square
 * @return A & B (register) the character code of the piece that moved
 * @return C (register) the character code of the piece that was captured (0 if none)
 * @return DE (register) destination square (unchanged)
 * @return HL (register) source square
*/
PMOVE:
    42ff : 2a 07 40    LD HL,(4007H) ; The two bytes at 4007H hold the source square, for the move
    4302 : 1a          LD A,(DE)     ; DE holds the destination square (0 for empty, charcode for capture)
    4303 : 4f          LD c,a        
    4304 : 7e          LD a,(HL)     ; get the character code of the piece that's moving
    4305 : 36 00       LD (HL),00H   ; clear the source square
    4307 : 12          LD (DE),A     ; write the character to the new square
    4308 : 47          LD b,a        
    4309 : c9          RET          

    ;source location stored here = 16391 = PPC Line number of statement currently being executed. Paqge 92 of [0].


/**
PSC gives a score to a chess piece Q(5), R(4), B(3), N(2), P(1).

 * @param A (register) character code of the piece in question (of either colour)
 * @return B (register) The score for that piece
 * @return A (register) 0 if the piece was not in the list QRBNP, otherwise it retains the character code
*/
PSC:
    430a : e6 7f       AND 7fH       ; mask, to ignore colour
    430c : 21 f2 40    LD hl,40f2H   ; points to the table holding character codes for the pieces QRBNP
    430f : 06 05       LD b,05H      
PSC_NOT_FOUND:
    4311 : be          CP A,(HL)     ; if the code matches...
    4312 : c8          RET z         ; ...return, with our B already holding the score
    4313 : 23          INC hl        
    4314 : 10 fb       DJNZ (PSC_NOT_FOUND) ; also decrements B, until B=0
    4316 : 78          LD a,b        ; QQ. Is this used?
    4317 : c9          RET          


INC_BEING_ATTACKED:
/**
INC
determines whether a square is being attacked.

 * @param L (register) LSB of square's location
 * @return A (register) whatever C was on entry
 
 From SQUARE_ATACK. we also return
 * @return C (flag) 1 = can attack square, 0 = can not attack square

@see SQUARE_ATACK
*/
    4318 : 7d          LD a,l        
    4319 : d9          EXX          ; exchange with a complete set of shadow registers
    431a : 32 80 40    LD (ATTACK_REGISTER),A  
    431d : cd 10 42    CALL (SQUARE_ATACK)  
    4320 : d9          EXX          ; switch back
    4321 : 79          LD a,c        
    4322 : c9          RET


JUNK:?!?!?!? Free memory
4323 : 76          HALT          
4324 : 00          nop          
4325 : 02          LD (BC),A    
4326 : 02          LD (BC),A    
4327 : 00          nop          
4328 : e4 76 00    CALL po,0076H
432b : 03          INC bc        
432c : 04          INC b        
432d : 00          nop          
432e : f9          LD SP,HL      
432f : d4 3d 76    CALL nc,763dH
; Screen display
; [118]
; 4 blanks lines (also 118)
; [black] [grey] DRH as 80 08 a9 b7 ad
SCREEN_DISPLAY:
4332 : 76          HALT          
4333 : 76          HALT          
4334 : 76          HALT          
4335 : 76          HALT          
4336 : 76          HALT          
; DRH line
4337 : 80          ADD A,b      
4338 : 08          EX AF,AF'
4339 : a9          XOR A,c      
433a : b7          OR A,a        
433b : ad          XOR A,l      
433c : 76          HALT          
433d : 1d          DEC e        
433e : 08          EX AF,AF'
; H1
433f : 37          SCF          
4340 : 33          INC sp        
4341 : 27          DAA          
4342 : 30 36       JR nc,(PC+36H)
4344 : 27          DAA          
4345 : 33          INC sp        
4346 : 37          SCF          
4347 : 76          HALT          
4348 : 1e 08       LD e,08H      
434a : 35          DEC (HL)      
434b : 35          DEC (HL)      
434c : 35          DEC (HL)      
434d : 35          DEC (HL)      
434e : 80          ADD A,b      
434f : 35          DEC (HL)      
4350 : 35          DEC (HL)      
4351 : 35          DEC (HL)      
4352 : 76          HALT          
4353 : 1f          RRA          
4354 : 08          EX AF,AF'
4355 : 00          nop          
4356 : 80          ADD A,b      
4357 : 00          nop          
4358 : 80          ADD A,b      
4359 : 35          DEC (HL)      
435a : 80          ADD A,b      
435b : 00          nop          
435c : 80          ADD A,b      
435d : 76          HALT          
435e : 20 08       JR nz,(PC+08H)
4360 : 80          ADD A,b      
4361 : 00          nop          
4362 : 80          ADD A,b      
4363 : 00          nop          
4364 : 80          ADD A,b      
4365 : 00          nop          
4366 : 80          ADD A,b      
4367 : 00          nop          
4368 : 76          HALT          
4369 : 21 08 00    LD hl,ERROR_1
436c : 80          ADD A,b      
436d : 00          nop          
436e : 80          ADD A,b      
436f : 00          nop          
4370 : 80          ADD A,b      
4371 : 00          nop          
4372 : 80          ADD A,b      
4373 : 76          HALT          
4374 : 22 08 80    LD (8008H),HL
4377 : 00          nop          
4378 : 80          ADD A,b      
4379 : 00          nop          
437a : 80          ADD A,b      
437b : 00          nop          
437c : 80          ADD A,b      
437d : 00          nop          
437e : 76          HALT          
437f : 23          INC hl        
4380 : 08          EX AF,AF'
4381 : b5          OR A,l        
4382 : b5          OR A,l        
4383 : b5          OR A,l        
4384 : b5          OR A,l        
4385 : b5          OR A,l        
4386 : b5          OR A,l        

4387 : b5          OR A,l        
4388 : b5          OR A,l        
4389 : 76          HALT          
438a : 24          INC h        
438b : 08          EX AF,AF'
438c : b7          OR A,a        
438d : b3          OR A,e        
438e : a7          AND A,a      
438f : b0          OR A,b        
4390 : b6          OR A,(HL)    
4391 : a7          AND A,a      
4392 : b3          OR A,e        
4393 : b7          OR A,a        
; ^^ the final rook, on A8
4394 : 76          HALT          
4395 : 08          EX AF,AF'
4396 : 08          EX AF,AF'
4397 : 2d          DEC l        
4398 : 2c          INC l        
4399 : 2b          DEC hl        
439a : 2a 29 28    LD HL,(2829H)
439d : 27          DAA          
439e : 26 76       LD h,76H      
; Input buffer : DD SS
INPUT_BUFFER:
43a0 : 08          EX AF,AF'
43a1 : 08          EX AF,AF'
43a2 : 08          EX AF,AF'
43a3 : 08          EX AF,AF'
43a4 : 08          EX AF,AF'
; end of screen, 9 blank lines
43a5 : 76          HALT          
43a6 : 76          HALT          
43a7 : 76          HALT          
43a8 : 76          HALT          
43a9 : 76          HALT          
43aa : 76          HALT          
43ab : 76          HALT          
43ac : 76          HALT          
43ad : 76          HALT          
; end



/*
References

[0] www.retro8bitcomputers.co.uk/Content/downloads/manuals/zx81-basic-manual.pdf

*/
