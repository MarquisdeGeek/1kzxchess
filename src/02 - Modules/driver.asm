

DRIVER:
/**
Driver Main control logic, uses all the other subroutines to provide program control.
*/
.get_user_input:
.erase_user_input_area:
    LD b,05H      ; 5 characters to write
    LD a,08H      ; the grey hash character
    LD hl,439fH   ; bottom row of the display, where the user enters the move
.erase_loop:
    INC hl        
    LD (HL),a    
    DJNZ (.erase_loop)

.get_input:
    CALL (@KYBD)    ; get the source location, returned in HL
    CP 03H        
    JR nz,(.get_user_input) ; If it's not same coloured piece as player (3) retry

    LD (4007H),HL  ; HL holds the memory addr (in screen memory) of the piece to move
    LD e,l         ; now the E register holds the LSB of the piece position. This is (almost) never changed
    CALL (PIECE)   ; get all possible moves for this piece

    LD hl,43a1H    ; prepare to write destination move into $43a1, which is screen memory
    CALL (KYBD)    ; get destination location, returned in HL

    CP 02H         ; 0,1 produce a carry. 2 and 3 don't
    EX DE,HL       ; DE now holds dest, and HL holds source
    JR nc,(.get_user_input) ; so if target is 2 or 3 (wall or same colour) we jump back to the start
    ; QQ. is the above necessary, if we have a list of valid moves?!?!?!

.check_next_move:
    CALL (TEST_LIST)  
    JR z,(DRIVER) ; if no valid moves left, jump back to start to get new input move
    CP c        ; if the square returned from TEST_LIST, in A, does not match the destination square the player entered (in C)...
    JR nz,(.check_next_move) ; ... try the next move in the list

    CALL (PIECE_MOVE)  ; move the player's piece (HL still holds the source square)

    EXX           ; save our registers, in case we need to revert the move
    CALL (CHECK_FOR_CHECK)  
    EXX          
    JR c,(.human_moved_into_check)

    ; AI's turn
    CALL (REPAIR_BOARD_SQUARE)  
    CALL (MPSCAN)

.stepping_stone: ; needed because the code below can't reference the start of the loop directly
    JR (DRIVER)  

.human_moved_into_check:
    LD (HL),b    ; replace the human piece on the source square
    LD a,c       ; C still holds the captured piece from PIECE_MOVE
    LD (DE),A    ; replace the captured piece onto the destination square
    JR (.stepping_stone)  

