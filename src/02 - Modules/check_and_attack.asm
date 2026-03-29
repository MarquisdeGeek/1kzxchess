
CHECK_FOR_CHECK:
/**
CHECK locates current mover's Kings and stores the position in the attack register.

It then drops through to determine if that piece is being attacked.

 * @return C (flag) 1 = is in check, 0 = not in check
*/
    LD A,(4337H)  ; screen holding curent player. 128=black, 0=white
    ADD A,30H     ; character for K, so A is now either a white K ($30), or black/inverse K ($B0)
    LD hl,433eH   ; grey square, immediately before H1 (white rook)
    LD b,a        
    CPIR          ; searches by comparing A with all squares until it finds the king
    DEC hl        ; since CPIR overshoots by 1 byte, this compensates
    LD (ATTACK_REGISTER),HL
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
    LD b,56H     ; there are 86 bytes which might have an opponent piece on (we worry about
                        ; excluding the edges, as they don't have any character codes that would
                        ; erroneously match a real piece)
    LD hl,433eH  ; the square immediately before the first
.next_square_on_board:
    INC hl        
    PUSH hl      
    PUSH bc      
    LD e,l        ; E now holds the LSB of the square's location, as it usually does
    CALL (STR_DETERMINE_SQUARE_CONTENTS_AT_HL)  ;  we have already set the position of the interesting square into HL, so jump part-way into the STR_DETERMINE_SQUARE_CONTENTS code
    CP 00H        
    JR nz,(.not_an_opponent_piece)

    CALL (CHANGE_CURRENT_MOVER)  ; consider from opponent's POV
    LD l,e        ; recover square of interest, since CHANGE_CURRENT_MOVER destroys L
    CALL (PIECE)  ; find all positions that this opponent's piece can move to
    CALL (CHANGE_CURRENT_MOVER)  ; switch POV back

    ; check move list
.not_found:
    CALL (TEST_LIST) ; get the first/next possible move into A
    JR z,(.no_moves_left)

    LD HL,(ATTACK_REGISTER)
    CP l        
    JR nz,(.not_found)
    ; getting here means "found a piece that can attack"
    POP bc        
    POP hl        
    SCF          ; set carry flag to indicate success, opposition can attack here
    RET          

.no_moves_left:
.not_an_opponent_piece:
    POP bc        
    POP hl        
    DJNZ (.next_square_on_board)
    AND a      ; also clears the flag flag
    RET          
