https://users.ox.ac.uk/~uzdm0006/scans/1kchess/

Below is the result of running OCR on the third page of the 1K ZX81 Chess article in Your Computer, after spell-checking, reformatting and removing any obvious mistakes. There are still likely to be many mistakes, mainly in the numbers column (watch out for zeros being mistaken for 8s). The two or three pencilled in corrections from the magazine are incorporated.
The columns are listed in a logical order as far as they appear on the page (the top section, left to right, then the bottom, left to right) and separated by horizonal lines (there is also a line above `SHIFT' where the type changes size). However, this is far from logical as far as the program goes so you will have to rearrange the sections based on the addresses given.

https://users.ox.ac.uk/~uzdm0006/scans/1kchess/assem.html

Q. entry point?
16959, LD B, 5

I missed this line:
LET X= 16959



TKP
16514 PUSH HL   229
(138) PUSH BC   197
( 64) CALL NN   205 187 2
      LD B H    68
      LD C L    77
      LD D L    85
      INC D     28
      JP Z DIS  48 247
      CALL NN   205 189 7
      LD A (HL) 126
      POP BC    193
      PUSH BC   197
      CP C      185
      JP Z DIS  40 6
      INC C     12
      DJNZ DIS  16 250
      POP BC    193
      JR DIS    24 231
      POP BC    193
      POP HL    225
      LD(HL) A  119
      RET       201
KYBD
/*
Kybd
is a routine which sets up machine control of
the keyboard such that only the eight key
codes from code 29 and the eight key codes
from code 38 are acceptable entries. Any other
key depression is ignored. 

The subroutine
TKP just scans the keyboard waiting for an
appropriate key to be depressed. The alpha-
numeric entry is then translated to a board
address.
*/

16544 LD BC NN   1 29 8
(168) CALL NN    205  130 64
( 64) DEC HL     43
      LD C N     14 3
      CALL NN    205 130 64
      INC HL     35
16557 LD A (HL)  126
      SUB N      214 28
      LD B A     71
      LD C N     14 11
      XOR A      175
      ADD C      129
      DJNZ DIS   16 253
      ADD N      198 97
      DEC HL     43
      SUB (HL)   150
/*
Move produces a list of all legal moves
available to the piece under consideration.
*/
MOVE
      LD A E     123
      ADD A (HL) 134
      PUSH AF    245
      PUSH HL    229
      PUSH BC    197
      CP N       254 63
      JP C DIS   56 38

      CP N       254 148
      JP NC DIS  48 26
      CALL STR   205 187 64
      CP N       254 2
      JP NC DIS  48 19
      PUSH AF    245
      CALL ALIST 205 141 66
      POP AF     241
      CP N       254 0
      JP Z DIS   48 10
      POP BC     193
      POP HL     225
      LD A C     121
      CP N       254 1
      JP Z DIS   40 5
      POP AF     241
      JR DIS     24 218
      POP BC     193
      POP HL     225
      POP AF     241
      INC HL     35
      DJNZ DIS   16 211
      RET        201 

/*
STR: this routine takes the board address
and determines whether the contents
are: different from the current mover colour;
empty; the board surround or the same
colour as the current mover.
*/

STR
16571 LD C A     79
(187) LD L A     105
( 64) LD H N     38 67
16575 LD A (HL)  126
(191) LD B N     6  1
( 64) AND N      230 127
      CP N       254 0
      JP Z DIS   40 20
      INC B      4
      CP N       254 118
      JP Z DIS   40 15
      CP N       254 39
      JP C DIS   56 11
      LD A (HL)  126        '0' DIFF
      INC B      4
      LD L N     45 55      '1' EMPTY
      ADD (HL)   134
      BIT 7,A    283 127    '2' WALL
      JP Z DIS   48 2
      LD B N     6  0       '3' SAME
      LD H B     128
      LD L C     185
      RET        291
TABLES
16607 1 11 -1 -11 -10 -12 12 10
16615 13 -13 21 -21 23 -23 -9 9
16623 11 10 12
16626 54 55 39 51 53

/*
Piece: this sets up pointers to possible move
tables and number of steps and directions.
*/
PIECE
16631 XOR A      175
(247) LD (NN) A  50 70 64
( 64) LD A (HL)  126
      AND N      230 127
      CP P       254 53
      JP Z DIS   48 73
      LD C N     14 1
      LD B N     6  8
      LD HL NN   35 231 64
      CP N       254 51
      JP Z DIS   40 22
      LD H N     46 223
      CP K       254 48
      JP Z DIS   48 16
      LD C B     72
      CP Q       254 54
      JP Z DIS   48 11
      LD B N     6 4
      CP R       154 55
      JP Z DIS   40 5
      LD L N     46 227
      CP B       254 39
      RET NZ     192
/*
 Shift moves the current move list to a safe
position whilst Check is being evaluated, and
then recovers the move list on completion. It is
also used to shift the best move so far up into
the move list.*/

SHIFT
16882 LD HL NN   33 99 64
(242) LD DE NN   17 78 64
( 65) LD BC NN   1  98 0
      JP C DIS   56 1
      EX DE HL   235
      LDIR       237 176
      RET        201
/*
PSC gives a score to a chess piece Q(5),
R(4), B(3), N(2), P(1).
*/
PSC
17162 AND N      230 127
(10)  LD HL NN   33 242 64
(67)  LD B N     6 5
      CP (HL)    190
      RET Z      200
      INC HL     35
      DJNZ DIS   16 251
      LD A B     120
      RET        201

/*
MPScan scans the board for computer
pieces and, using move and score, determines
all legal moves and saves the best. INC
determines whether a square is being attacked.
*/
MPSCAN
17846 XOR A      175
(158) LD (NN) A  50 69 64
( 66) LD B N     6  86
      LD HL NN   33 62 67
      INC HL     35
      PUSH HL    229
      PUSH BC    197
      LD E L     93
      CALL STR   205 191 64
      CP N       254 3
      JP NZ DIS  32 41
      LD L E     187
      LD (NN) HL 34 7 64
      CALL MOVE  205 247 64
      CALL TL    205 130 66
      JP Z DIS   48 23
      LD E A     95
      LD D N     22 67
      CALL PMOVE 205 255 66
      EXX        217
      AND A      167 

      CALL SHIFT 205 242 65
      CALL CHK   205 1 66
      EXX        217
      LD(HL) B   112
      LD A C     121
      LD(DE) A   18
      JP C DIS   56 3
      CALL SCORE 205 153 65
      SCF        55
      CALL SHIFT 205 242 65
      JP DIS     24 222
      POP BC     193
      POP HL     225
      DJNZ DIS   16 288
      LD A (NN)  58 65 64
      CP N       254 0
      JP Z DIS   48 254
      LD HL NN   38 69 64
      LD A (HL)  126
      DEC HL     48
      DEC HL     43
      LD E (HL)  94
      LD D N     22 67
      LD (DE) A  18
      DEC HL     41
      LD L (HL)  110
      LD H D     98
17131 BIT B,L    203 69
(235) LD(HL) N   54 0
( 66) JP Z DIS   48 2
      LD(HL) N   54 128
      CALL CHGMV 205 247 66
      RET        201
INC
17176 LD A L     125
(24)  EXX        217
(67)  LD(NN) A   58 128 64
      CALL SQ.AT 205 16 66
      EXX        217
      LD A C     121
      RET        201
/*
Driver Main control logic, uses all the
other subroutines to provide program control.
*/
DRIVER
16959 LD B N     6 5
(63)  LD A N     62 0
(66)  LD HL NN   33 159 67
      INC HL     35
      LD(HL) A   119
      DJNZ DIS   16 251
      CALL KT    205 168 64
      CP N       254 3
      JP NZ DIS  32 29
      LD (NN) HL 34 7 64
      LD E L     93
      CALL MOVE  205 247 64
      LD HL NN   93 161 67
      CALL KT    205 18 64
      CP N       245 2
      EX DE HL   235
      JP NC DIS  48 29
      CALL TL    205 138 66
      JP Z DIS   48 215
      CP C       185
      JP NZ DIS  32 248
      CALL PMOVE 205 255 66
      EXX        217
      CALL CHK   205 1 66
      EXX        217
      JP C DIS   56 8
      CALL CHGSQ 295 295 66
      CALL MPSCAN 205 150 66
      JP DIS     24 194
      LD (HL) B  112
      LD A C     191
      LD (DE) A  18
      JP DIS     24 249
/*
TestList: tests to see if there are any moves
in the move list.
*/
TEST LIST
17826 LD HL NN   33 78 64
(138) DEC (HL)   53
( 66) LD A (HL)  126
      INC A      68
      RET Z      200
      ADD L      193
      LD L A     111
      LD A (HL)  196
      RET        201

/*
Pawn produces a list of all possible legal
moves including initial double moves.
*/
PAWN
16721 LD A (HL)  126
(81)  ADD N      238 128
(65)  LD HL NN   33 228 64
      JP NZ DIS  32 2
      LD L N     46 241
      LD D N     22 3
      LD A E     123
      ADD (HL)   134
      PUSH HL    229
      PUSH AF    245
      CP N       254 63
      JP C DIS   56 32
      CP N       254 148
      JP NC DIS  48 28
      CALL STR   205 187 64
      CP N       254 0
      JP Z DIS   48 28
      CP N       254 1
      JP NZ DIS  32 17
      LD A D     122
      CP N       254 1
      JP NZ DIS  32 12
      CALL ALIST 205 141 66
      LD A E     123
      CP N       254 82
      JP C DIS   56 19
      CP N       254 126
      JP NC DIS  48 15
      POP AF     241
      POP HL     225
      DEC HL     43
      DEC D      21
      JP NZ DIS  31 218
      RET        201
      LD A D     122
      CP M       254 1
      CALL NZ ALIST 196 141 66
      JP DIS     24 241
      POP AF     241
      POP HL     225
      LD E A     95
      JP DIS     24 197
CHK
16897 LD A (NN)  58 55 67
( 1)  ADD N      198 48
(66)  LD HL NN   33 62 67
      LD B A     71
      CPIR       237 177
      DEC HL     43
      LD (NN) HL 34 128 64
SQ.AT LD B N     6 86
16912 LD HL NN   38 62 67
(16)  INC HL     35
(66)  PUSH HL    229
      PUSH BC    197
      LD E L     93
      CALL STR2  205 191 64
      CP 8       254 8
      JP NZ DIS  32 25
      CALL CHEMV 205 247 66
      LD L E     187
      CALL MOVE  205 247 64
      CALL CHEMV 205 247 66
      CALL TL    205 138 66
      JP Z DIS   48 18
      LD HL(NN)  42 128 64

      CP L       189
      JP NZ DIS  32 245
      POP BC     193
      POP HL     925
      SCF        55
      RET        201
      POP BC     193
      POP HL     225
      DJNZ DIS   16 216
      AND A      167
      RET        201

/*
Score provides a move score based on the
following: first, the "To" position results in
taking of a piece. Second, the "From" position
is attacked. Third, the "To" position is
attacked. Fourth, "To" enables the computer
to obtain a check and finally the "From"
position is defended.
    The current move score is then compared
with the previous best and if this is superior,
the move is saved as the best so far.
*/
SCORE
16793 PUSH HL    229
(153) PUSH BC    197
(65)  PUSH DE    213
      PUSH HL    229
      PUSH BC    197
      LD D L     85
      LD HL NN   33 64 64
      CALL NN    205 36 7
      CALL PSC   205 18 67
      LD A B     128
      ADD A H    132
      LD C A     73
      POP AF     241
      CALL PSC   205 18 67
      POP HL     225
      CALL INC   205 24 67
      JP NC DIS  48 1
      ADD A B    128
      LD C A     79
      POP HL     225
      POP DE     289
      LD E (HL)  94
      LD (HL) D  114
      PUSH HL    219
      PUSH DE    213
      CALL INC   205 24 67
      JP NC DIS  48 1
      SUB B      144
      PUSH AF    245
      CALL CHEMV 205 247 66
      CALL CHK   205 1 66
      POP BC     193
      JP NC DIS  48 2
      INC B      4
      INC B      4
      POP DE     209
      POP HL     225
      LD (HL) E  115
      POP HL     225
      CALL CHG   205 250 66
      CALL INC   205 24 67
      JP NC DIS  48 1
      DEC B      5
      CALL CHG   205 250 66
      CALL CHEMV 205 247 66
      LD A B     128
      LD HL NN   33 68 64
      LD (HL) A  119
      EX DE HL   235
      LD HL NN   33 65 64
      CP (HL)    198
      RET C      216
      LD BC NN   1  5  0
      JP DIS     24 11



17287         LD HL NN   33 67 67    (17219)
              LD DE NN   17 0 72     (18432)
              LD BC NN   1 205 0
              LDIR       237 176
              RET        201
17219  18432  128 8 169 183 173 118
              29 8 55 51 39 48 54 39 51 55 118
17236         30 8 53 53 53 53 53 53 53 53 118
              31 8 0 128 0 128 0 128 0 128 118
17258         32 8 128 0 128 0 128 0 128 0 118
              33 8 0 128 0 128 0 128 0 128 118
17280         34 8 128 0 128 0 128 0 128 0 118
              35 8 181 181 181 181 181 181 181
              181 118
17302         36 8 183 179 167 176 182 167 179
              183 118
              8 8 45 44 43 42 41 40 39 38 118
17324         8 8 8 8 8
17329  18542  LD BC NN   1 0 4
              CALL NN    205 245 8     (2293)
              LD HL NN   33 0 72
              LD B N     6 110
              PUSH BC    197
              PUSH HL    229
              LD A (HL)  126
              RST 16     215
              POP HL     225
              POP BC     193
              INC HL     35
              DJNZ       16 247
17349  18562

              LD HL NN   33 125 64     16509
              LD (NN) HL 34 41 64      16425
              JP NN      195 7 3


Figure 4. Code map. See also page 102.
/*
AddList: adds to the current
legal move list another entry on the end.
*/
ALIST
17837  LD HL NN   33 70 64
(141)  INC (HL)   52
( 66)  LD A (HL)  126
       ADD L      133
       LD L A     111
       LD (HL) C  113
       RET        201
CHGMV
17143  LD HL NN   33 55 67
(247)  LD A (HL)  126
( 66)  ADD N      198 128
       LD(HL) A   119
       RET        201
PMOVE
17151  LD HL (NN) 42 7 64
(255)  LD A (DE)  26
( 66)  LD C A     79
       LD A (HL)  126
       LD(HL) N   54 0
       LD(DE) A   18
       LD B A     71
       RET        201

       
         © Copyright David Horne 1983

