
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
    LD a,l        
    EXX          ; exchange with a complete set of shadow registers
    LD (ATTACK_REGISTER),A  
    CALL (SQUARE_ATACK)  
    EXX          ; switch back
    LD a,c        
    RET

