
SCORE_MOVEMENT:
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
    PUSH hl       ; (pop at $41d2)
    PUSH bc       ; (pop at $41bc as DE)
    PUSH de       ; (pop at $41b7 as HL)
    PUSH hl       ; (pop at $41af)
    PUSH bc       ; (pop at $41ab as AF)
    LD d,l        ; backup the LSB of our source square, so it gets saved by ROM_COPY_REGISTERS
    LD hl,SCORE_SCRATCHPAD_END ; note that we write out values backwards  
    CALL (ROM_COPY_REGISTERS)  ; borrow a routine from ROM to write B, C, E, D (in that order) to the address of HL, HL-1, HL-2, and HL-3

    CALL (GET_SCORE_FOR_PIECE)  ; get a material score/value for the captured piece (held in A). Returned in B
    LD a,b        ; our initial score is the material value of our piece
    ADD A,h         ; we increment by $40 (the high byte of SCORE_SCRATCHPAD_END) to avoid negatives 
                            ; later on. it also ensures that _any_ valid move scores some points, so 
                            ; we can determine a checkout when the best move scores 0
    LD c,a        ; keep the score safe, in C
    POP af        ; when we pushed BC it held B as the moved piece. that is now removed and placed in A

    CALL (GET_SCORE_FOR_PIECE)    ; material value of the piece we moved
    POP hl        ; recover the source location

    CALL (INC_BEING_ATTACKED)  ; this indicates whether the _opposition_ is being attacked from HL
    JR nc,(.dont_add) ; if _they_ weren't being attacked, don't increase the score
    ADD A,b      ; amend local score by value of piece
.dont_add:
    LD c,a        ; keep the score safe, in C
    POP hl        ; HL is now the destination square address (was DE upon entry)
    POP de        ; D=character code of piece moving (was B upon entry)
    LD e,(HL)     ; get the character code of the piece in the destination square
    LD (HL),d     ; move our piece into the target square, potentially capturing something
    PUSH hl      
    PUSH de      
    CALL (INC_BEING_ATTACKED)  ; is the opposition being attacked from our new position?
    JR nc,(.dont_sub)   ; ??
    SUB b      
.dont_sub:
    PUSH af      
    CALL (CHANGE_CURRENT_MOVER)  ; change sides so we can...
    CALL (CHECK_FOR_CHECK)    ; see if the human has been placed in check
    POP bc        ; recovers the score into B 
    JR nc,(.dont_score_for_check) ; and if not in check, skip. i.e. if they are checked, continue and add 2 points
    INC b        
    INC b        
.dont_score_for_check:
    POP de        ; recover DE from $41bc (where D holds character code of moving piece, E is captured piece)
    POP hl        ; recover HL from $41bb (which holds address of destination square)
    LD (HL),e     ; replace capture piece back on board
    POP hl        ; recover HL from $4199 (source square)

    CALL (CHANGE_CURRENT_MOVER_AT_HL)  ; toggle the white AI piece, in its source square, to be black
    CALL (INC_BEING_ATTACKED)  
    JR nc,(.dont_sub2) ; not being attacked
    DEC b        
.dont_sub2:
    CALL (CHANGE_CURRENT_MOVER_AT_HL)  ; toggle piece back to white
    CALL (CHANGE_CURRENT_MOVER)     ; change player back to white

    ; Finally, compare this score with the best
    LD a,b        
    LD hl,SCORE_SCRATCHPAD
    LD (HL),a        ; store the score for this move
    EX DE,HL      
    LD hl,BEST_MOVE_DETAILS      ; prepare to compare the existing best score (in HL)
    CP (HL)        ; if local score < best score, the carry flag set
    RET c            ; so this RETurns if the score isn't as good
    ; new best score found
    LD bc,0005H      ; prepare to copy 5 bytes from DE to HL
                            ; DE = local, current, score
                            ; HL = global, best score
    JR (SWITCH_MOVE_LIST_BUFFER_REVERSE)  ; the reverse ensures DE becomes HL, the actual source of the copy
