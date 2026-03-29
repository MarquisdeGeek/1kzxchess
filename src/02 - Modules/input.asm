
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
