; We use these 3 ROM routines
ROM_KEYBOARD        equ $02bb
ROM_DECODE          equ $07bd
ROM_COPY_REGISTERS  equ $0724

; Enum used by STR_DETERMINE_SQUARE_CONTENTS
SQUARE_IS_DIFFERENT_COLOUR equ 0
SQUARE_IS_EMPTY equ 1
SQUARE_IS_BOARD_EDGE equ 2
SQUARE_IS_SAME_COLOUR equ 3


	ORG $4082

TKP:
/**
The subroutine TKP just scans the keyboard waiting for an appropriate key to be depressed. The alpha-
numeric entry is then translated to a board address.

 * @param B (register) Holds 8, the number of allowed options
 * @param C (register) Holds the character code (either $1D or $26) of the first allowed option
 * @return (HL) (memory) The character code of the entered key
*/
    PUSH hl      
.not_found:
    PUSH bc      

.loop:
    CALL (ROM_KEYBOARD)
    ; ROM_KEYBOARD returns the key in HL, as row and mask
    LD b,h        ; DECODE needs value in BC, so copy from HL
    LD c,l        
    LD d,l        
    INC d        
    JR z,(.loop)  ; i.e. no keys are pressed, because mask was $ff and INCremented to 0
    CALL (ROM_DECODE)
    LD a,(HL)     ; A now has key code, write to screen
    POP bc        
    PUSH bc      
.retry:
    CP C        ; is it the current allowed character?
    JR z,(.found)
    INC c        
    DJNZ (.retry)
    ; All 8 tried, and failed
    POP bc        
    JR (.not_found)  
.found:
    POP bc        
    POP hl        
    LD (HL),a    
    RET          

KYBD:
/**
KYBD is a routine which sets up machine control of the keyboard such that only the eight key
codes from code 29 and the eight key codes from code 38 are acceptable entries. Any other
key depression is ignored.

29 ($1D) = 1
38 ($26) = A

For return codes:
@see STR_DETERMINE_SQUARE_CONTENTS
*/
    ; Get a number, 1-8
    LD bc,081dH  ; prepare TKP to accept any 8 characters from $1D onwards (i.e. digits)
    CALL (TKP)  
    DEC hl        ; screen memory to store and show square, reposition HL so TKP can store the letter
    ; Get a letter, A-H
    LD c,_A      ; since B is set, now accept characters from $26 onwards (i.e. A)
    CALL (TKP)  
    INC hl        
    LD a,(HL)     ; get the numbered row, again
    SUB 1cH       ; converts A from key code to number 1-8
    LD b,a        
    LD c,0bH      ; our loop multiplies this number by 11 (characters in row), result in A, through successive addition by .loop
    XOR a       ; sneaky A=0
.loop:
    ADD A,c      
    DJNZ (.loop)

    ADD A,61H     ; offset to board
    DEC hl        ; return to point HL at the column letter (which holds a character code)
    SUB (HL)   ; move along lettered columns. Because (HL) is a character code, 'A' ia $26
    ; fall through to STR_DETERMINE_SQUARE_CONTENTS


STR_DETERMINE_SQUARE_CONTENTS:
/**
This routine takes the board address and determines whether the contents
are: 

0 = different from the current mover colour (SQUARE_IS_DIFFERENT_COLOUR)
1 = empty (SQUARE_IS_EMPTY)
2 = the board surround (SQUARE_IS_BOARD_EDGE)
3 = the same colour as the current mover (SQUARE_IS_SAME_COLOUR)

 * @param A (register) the LSB address of the square in question (MSB of screen is $43)

 * @return A & B (register) one of the four values above
 * @return L (register) the LSB address of the square in question (MSB of screen is $43)
*/
    LD c,a        
    LD l,c        
    LD h,43H      ; screen MSB offset
STR_DETERMINE_SQUARE_CONTENTS_AT_HL:
    ; Get piece (from screen memory) at the position
    LD a,(HL)    
    LD b,01H      
    ; This mask clears the MSB, effectively ignoring the piece colour
    AND 7fH      
    CP 00H        
    ; If a blank square, B=1, jump to found
    JR z,(.found)
    INC b        
    ; If the right edge of board ($76=118=Halt), B=2, jump out
    CP 76H        
    JR z,(.found)
    ; When A < 76H it's also an edge, B is still 2, jump out
    CP 27H        
    JR c,(.found)
    ; if piece is same colour
    LD a,(HL)    
    INC b        
    LD l,37H      
    ADD A,(HL)    
    BIT 7,a      
    JR z,(.found)
    ; else, must be same colour, return B=0
    LD b,00H      
.found:
    LD a,b        
    LD l,c        
    RET          


; major piece movements are done via these lookup tables
; (pawns have additional logic)
TABLES: ; these are in decimal and represent relative offsets
    ; 16607 = $40dfH = king movements (8 bytes, shared by rooks, bishops and pawn)
TABLE_KING:
TABLE_ROOK:
    defb 1, 11, -1
TABLE_BLACK_MOVE_PAWN_END:
    ; 40e2 holds the black pawn movements (-11  -10 -12)
    ; Note that the pawn checker works backwards from $40e4, while the major
    ; pieces work forwards through their tables
    defb -11
    ; 40e3 holds the bishop movements, as the final 4 items in the king list (-10,-12,12,10)
TABLE_BISHOP:
    defb -10
TABLE_BLACK_MOVE_PAWN_START:
    defb -12
    defb 12, 10

;16615 = $40e7 = knight movements
TABLE_KNIGHT:
    defb 13, -13, 21, -21, 23, -23, -9, 9

; 16623 = $40f1 = white pawn
TABLE_WHITE_MOVE_PAWN:
    defb 11, 10, 12

;16626 Character codes for the pieces - QRNBP - in order, for GET_SCORE_FOR_PIECE to score them
TABLE_PIECE_SCORING:
    defb 54, 55, 39, 51, 53

 

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


SWITCH_MOVE_LIST_BUFFER:
/**
Shift moves the current move list to a safe position whilst Check is being evaluated, and
then recovers the move list on completion. It is also used to shift the best move so far up into
the move list.

 * @param C (flag) if clear, copy move list _to_ the backup. If set, copy _from_ backup to list
*/
    LD hl,MOVE_LIST_BACKUP  ; source addr
    LD de,MOVE_LIST  ; dest addr
    LD bc,1cH        ; copy only 28 bytes
    JR c,(SWITCH_MOVE_FROM_BACKUP) ; if carry flag is set skip over this, which...
SWITCH_MOVE_LIST_BUFFER_REVERSE:
    EX DE,HL      ; ...reverses direction of copy, from MOVE_LIST to BACKUP (e.g.)
SWITCH_MOVE_FROM_BACKUP:
    LDIR          ; copies bytes from consecutive address at HL, write into DE
    RET          


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
    CALL (KYBD)    ; get the source location, returned in HL
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


/**
CHANGE_CURRENT_MOVER, or change mover, toggle between the player and computer, from 0 to $80 and back

Note that the 'current player' variable is held on-screen as a white or black square.
*/
CHANGE_CURRENT_MOVER:
    LD hl,4337H  ; the top left location on-screen
CHANGE_CURRENT_MOVER_AT_HL:
    LD a,(HL)    ; either 0 or $80 if top left location, or toggle MSB in general
    ADD A,80H    ; rely on overflow to transition from $80 to 0
    LD (HL),a    ; write back
    RET          


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

