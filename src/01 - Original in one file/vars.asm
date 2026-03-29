	ORG $403c

; our SCORE routine stores its data here
SCORE_SCRATCHPAD:
    defb 0 ; score of this move
    defb 0 ; LSB of source square (D)
    defb 0 ; LSB of destination square (E)
    defb 0 ; Unused?? (C)
SCORE_SCRATCHPAD_END
    defb 0 ; Character code of the moved piece (B)


; when a better move is detected, it bulk copies the above 5 bytes into these 5
BEST_MOVE_DETAILS:
    defb 0 ; best score
    defb 0 ; LSB of source square (D)
    defb 0 ; LSB of destination square (E)
    defb 0 ; Unused?? (C)
    defb 0 ; Character code of the moved piece (B)


MOVE_LIST:
A_4046:
    defb 0 ; count of items in list
            ; first possible move
    dup $1C ; 28 possible moves
        defb 0
    edup


    ; Technically belongs to BASIC ROM. Sys var MEMBOT, calculator area[0]
MOVE_LIST_BACKUP:
    ; Backup for MOVE_LIST (in the SHIFT routine). $1c bytes. 28 = not enough space in all cases!?!?!
    ; TODO - BUT there's not space for all 28, as it overruns the space
    defb 0
    dup $17
        defb 0
    edup


ATTACK_REGISTER:
    defw 0 ; attack square, e.g. location of human players king

