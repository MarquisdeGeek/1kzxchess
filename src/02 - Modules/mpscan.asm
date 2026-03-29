
MPSCAN:
/**
MPScan scans the board for computer pieces and, using move and score, determines
all legal moves and saves the best.
*/
    XOR a      ; A=0, basically
    LD (BEST_MOVE_DETAILS),A  ; Best move score is now 0
    LD b,56H      ; Like the code at $4210, we overscan the board, knowing that edge pieces get rejected early
    LD hl,433eH   ; the square before H1, on top left
.next_square:
    INC hl        
    PUSH hl      
    PUSH bc      
    LD e,l        ; E holds the LSB of the source square, as usual
    CALL (STR_DETERMINE_SQUARE_CONTENTS_AT_HL)  ; determine the contents of the current square
    CP 03H        
    JR nz,(.not_ai_piece)    ; if it's not an AI piece, then skip

    LD l,e        
    LD (4007H),HL     ; make a note of the piece we plan to move
    CALL (PIECE)      ; get all possible moves
.next_move_from_list:
    CALL (TEST_LIST)  ; because a piece will never be at address 0, we re-use a return of 0 meaning "did not found"
    JR z,(.not_ai_piece)     ; and we jump if no moves in the list

    LD e,a         ; A was filled by TEST_LIST to contain a suitable destination location. Put it in the usual E reg
    LD d,43H       ; The MSB of the screen, making DE a valid screen ptr.
    CALL (PIECE_MOVE)   ; Make the move, returned as HL to DE. On-screen it looks like the machine is thinking.
    EXX          
    AND a       ; this also clears carry flag, so that the SWITCH_MOVE_LIST_BUFFER routine copies MOVE_LIST to a save store
    CALL (SWITCH_MOVE_LIST_BUFFER)  ; save the current list of moves
    CALL (CHECK_FOR_CHECK)    ; did we put the human player in check? (result is in carry flag, but don't use it yet)
    EXX          
    LD (HL),b     ; return the piece (B) to it's original position
    LD a,c        ; (just like we do when the player moves into check at $427d)
    LD (DE),A     ; return captured piece, if any (A) - remembering that HL=source square, DE=destination
    JR c,(.recover_move_list) ; if we put them in check (carry flag set back in $42c1) then skip the SCORE_MOVEMENT computation

    CALL (SCORE_MOVEMENT)  ; Knowing the move was valid, score it

.recover_move_list:
    SCF           ; set carry flag, so that the SWITCH_MOVE_LIST_BUFFER routine retrieve MOVE_LIST from the save store
    CALL (SWITCH_MOVE_LIST_BUFFER)  ; and do the retrieval, before continuing with the next move on the list
    JR (.next_move_from_list)  

.not_ai_piece:
    POP bc        
    POP hl        
    DJNZ (.next_square)

    ; once all squares have been considered...
    LD A,(BEST_MOVE_DETAILS)  
    CP 00H        ; if there are no moves for the AI...
.human_wins:
    JR z,(.human_wins) ;... we spin in an endless loop

    LD hl,4045H  ; final byte of BEST_MOVE_DETAILS
    LD a,(HL)    ; original B, character code of the piece to move
    DEC hl        
    DEC hl        
    LD e,(HL)    ; original E from $4043, the LSB of the best destination square
    LD d,43H     ; fixed screen offset
    LD (DE),A    ; move the piece into the destination square
    DEC hl        
    LD l,(HL)    ; original D from $4042, holding the LSB for the source square
    LD h,d       ; reconstruct HL to point to screen (saves a byte over LD d,43H)

    ; determine if the square we were on is white or black
REPAIR_BOARD_SQUARE:
    BIT 0,l      ; test the bit, doing a "is it even" check. Z=1 if even
    LD (HL),80H  ; write a black square
    JR z,(.was_black); but if it was even, skip the next bit..
    LD (HL),00H  ; ..to re-write as white
.was_black:
    CALL (CHANGE_CURRENT_MOVER)  ; switch back the human player here (not in the DRIVER loop, strangely!?!?!)
    RET          
