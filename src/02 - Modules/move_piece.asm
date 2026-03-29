
PIECE:
/**
Piece: this sets up pointers to possible move tables, and number of steps and directions.

Falls through to MOVE_MAJOR_PIECE

 * @param E (register) LSB of the memory address of the source location (not touched here, but used in MOVE_MAJOR_PIECE)
 * @param HL (register) screen location of piece to consider 
*/
    XOR a      
    LD (MOVE_LIST),A  ; reset the count of possible moves to 0
    LD a,(HL)    
    AND 7fH       ; mask off colour
    CP _P         ; is it a pawn? if so use the special logic
    JR z,(MOVE_PAWN)

    ; HL = ptr to table of permitted directions
    ; B = number of directions in the table
    ; C = number of times that direction may be moved (so king would have C=1, and queen C=8, using the same table)
    LD c,01H      
    LD b,08H      
    LD hl,40e7H   ; a table of knight moves
    CP _N         ; is it a knight?
    JR z,(MOVE_MAJOR_PIECE)

    LD l,$df      ; because H is already set to 40e7 above, we only change L, so HL=40df
    CP _K         ; is it the king?
    JR z,(MOVE_MAJOR_PIECE)

    LD c,b        ; c=b=8. Note that the order allows us to use a one byte LD c,b instead of LD C,8H
    CP _Q         ; is it the queen?
    JR z,(MOVE_MAJOR_PIECE)

    LD b,04H      
    CP _R         ; is it a rook?
    JR z,(MOVE_MAJOR_PIECE)

    LD l,$e3      ; H is still 40, so now HL=40e3 which are the diagonal movements of the king
    CP _B         ; is it a bishop? if not, RETurn
    RET nz        ; Z80 has these nice 'if flags, then return' to save JR z, followed by another JR

    ; having setup up B,C, and HL, fall through to MOVE_MAJOR_PIECE

MOVE_MAJOR_PIECE:
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
.next_direction:
    LD a,e        ; reset A to the source position
.next_along_direction:
    ADD A,(HL)    ; add offset from table and determine new square, stored into A
    PUSH af      
    PUSH hl      
    PUSH bc      
    CP 3fH        ; if A < $3F, i.e. off board (top), since H1 is $433F
    JR c,(.invalid_move)

    CP 94H        
    JR nc,(.invalid_move) ; if A >=$94, i.e. off board (bottom)

    CALL (STR_DETERMINE_SQUARE_CONTENTS)  
    CP SQUARE_IS_BOARD_EDGE  ; is target is 2 (wall) or 3 (same colour), consider invalid
    JR nc,(.invalid_move)

    PUSH af      
    CALL (ADD_TO_MOVE_LIST)  
    POP af        

    CP 00H        ; capture??
    JR z,(.continue_after_move)
    POP bc        
    POP hl        
    LD a,c        ; Can the piece move more spaces in this direction?
    CP 01H        ; (by checking if A==1, i.e. empty)
    JR z,(.on_next_direction) ; No - so end now, and move onto next dir

    POP af        ; recover a, holding new start position (i.e. origial A + (HL))
    JR (.next_along_direction) ; attempt to continue moving this the same direction  
.invalid_move:
.continue_after_move:
    POP bc        
    POP hl        
.on_next_direction:
    POP af        
    INC hl        ; move to next entry in list
    DJNZ (.next_direction) ; REM: decrements B, and jumps if !=0
    RET          
