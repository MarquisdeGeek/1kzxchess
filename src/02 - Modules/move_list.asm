
TEST_LIST:
/*
TestList: tests to see if there are any moves in the move list.

 * @return (A) (register) 0 if no moves, otherwise destination location of the next valid move
*/
    LD hl,MOVE_LIST  
    DEC (HL)      ; pre-emptively decrement the size of the list by 1
    LD a,(HL)    
    INC a        
    RET z         ; A=0 if nothing in list, return
    ADD A,l       ; move A to point to last entry in list (A is the LSB at this point)
    LD l,a        ; move A back into L, so the complete address is in HL
    LD a,(HL)     ; return move at end of list, having already eliminated from list
    RET          


ADD_TO_MOVE_LIST:
/*
This adds to the current legal move list by adding another entry on the end.

Essentially a stack,pushing new data to the end (at higher addresses), and removing from
the end (via TEST_LIST) later.

 * @param C (register) LSB of the destination location to be added
*/
    LD hl,MOVE_LIST
    INC (HL)      ; inc the size of the list, which our first byte
    LD a,(HL)    
    ADD A,l       ; move A to point to last entry in list (A is the LSB at this point)
    LD l,a        ; reconstruct HL so it points to next free entry. i.e. MOVE_LIST+count
    LD (HL),c     ; store it
    RET          

