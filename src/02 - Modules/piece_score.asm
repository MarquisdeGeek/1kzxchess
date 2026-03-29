
/**
GET_SCORE_FOR_PIECE gives a score to a chess piece Q(5), R(4), B(3), N(2), P(1).

 * @param A (register) character code of the piece in question (of either colour)
 * @return B (register) The score for that piece
 * @return A (register) 0 if the piece was not in the list QRBNP, otherwise it retains the character code
*/
GET_SCORE_FOR_PIECE:
    AND 7fH       ; mask, to ignore colour
    LD hl,40f2H   ; points to the table holding character codes for the pieces QRBNP
    LD b,05H      
.not_found:
    CP (HL)     ; if the code matches...
    RET z         ; ...return, with our B already holding the score
    INC hl        
    DJNZ (.not_found) ; also decrements B, until B=0
    LD a,b        ; QQ. Is this used?
    RET          
