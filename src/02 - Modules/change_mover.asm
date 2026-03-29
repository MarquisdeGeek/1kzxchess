

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
