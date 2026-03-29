

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

 