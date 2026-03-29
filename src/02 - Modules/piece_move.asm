
/**
PIECE_MOVE moves a piece

 * @param 4007H (memory) source square
 * @param DE (register) destination square
 * @return A & B (register) the character code of the piece that moved
 * @return C (register) the character code of the piece that was captured (0 if none)
 * @return DE (register) destination square (unchanged)
 * @return HL (register) source square
*/
PIECE_MOVE:
    LD HL,(4007H) ; The two bytes at 4007H hold the source square, for the move
    LD A,(DE)     ; DE holds the destination square (0 for empty, charcode for capture)
    LD c,a        
    LD a,(HL)     ; get the character code of the piece that's moving
    LD (HL),00H   ; clear the source square
    LD (DE),A     ; write the character to the new square
    LD b,a        
    RET          
