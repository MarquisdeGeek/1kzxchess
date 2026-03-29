

MOVE_PAWN:
/**
Pawn produces a list of all possible legal moves including initial double moves.

 * @param HL (register) screen location of piece to consider 
*/
    LD a,(HL)     ; re-grab the piece 'P' into A
    AND 80H       ; 80H for black, 0 for white
    LD hl,40e4H   ; HL to reference the 3 valid move offsets by borrowing from the king's movement, -11  -10 -12, point to last of these
    JR nz,(.is_black)
    LD l,$f1      ; HL is now $40f1, the special pawn offsets (11 10 12) for white
.is_black:
    LD d,03H      ; D is our count of the 3 possible directions a pawn can move
.next_direction:
    LD a,e        
.next_along_direction:
    ADD A,(HL)    
    PUSH hl      
    PUSH af      
    CP 3fH        ; if A<64 it's invalid because off the board
    JR c,(.invalid_move)
    CP 94H        ; if A>=148, it's also off board
    JR nc,(.invalid_move)

    CALL (STR_DETERMINE_SQUARE_CONTENTS)    ; we're still considering our colour, at this point
    CP SQUARE_IS_DIFFERENT_COLOUR        ; is piece on target square a different colour?
    JR z,(.possible_capture)

    CP SQUARE_IS_EMPTY        ; if anything but empty (i.e. wall or same colour), so invalid
    JR nz,(.invalid_move)

    LD a,d        
    CP 01H        ; moving -10 or -12 is only permitted in capture. If we're here, then we're not capturing, so fail
    JR nz,(.invalid_move)

    CALL (ADD_TO_MOVE_LIST)
    LD a,e        
    CP 52H        ; if A < $52 the pawn is in row 1 or 2, so might be able to move again
                         ; this check happens for pawns of either colour. This is allowed because
                         ; white pawns are never in row 1, and black pawns (if they reach row 2) have
                         ; only one row left to move and so those moves are rejected as being off the
                         ; top of the board
    JR c,(.may_move_twice)
    CP 7eH        ; if A>= $7e the pawn is in row 7 or 8
    JR nc,(.may_move_twice)

.invalid_move:
.continue_move:
    POP af        
    POP hl        
    DEC hl        ; move to next possible move offset
    DEC d         ; any more offets in the list?
    JR nz,(.next_direction)
    RET          

.possible_capture:
    LD a,d        
    CP 01H        
    CALL nz,ADD_TO_MOVE_LIST  ; if the piece is anything but 1 (empty), then it's a capture
    JR (.continue_move)

.may_move_twice:
    POP af        
    POP hl        
    LD e,a        ; set the current position to be the first single space move
    JR (.next_along_direction)   ; we can then re-check for another single space move. (It helps that the single forward move is the last one checked)

