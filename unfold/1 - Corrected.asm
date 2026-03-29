TKP:
/*
The subroutine
TKP just scans the keyboard waiting for an
appropriate key to be depressed. The alpha-
numeric entry is then translated to a board
address.
*/

    4082 : e5          PUSH hl       
    4083 : c5          PUSH bc       
    4084 : cd bb 02    CALL (KEYBOARD)
    4087 : 44          LD b,h        
    4088 : 4d          LD c,l        
    4089 : 55          LD d,l        
    408a : 14          INC d         
    408b : 28 f7       JR z,(PC+f7H) 
    408d : cd bd 07    CALL (DECODE) 
    4090 : 7e          LD a,(HL)     
    4091 : c1          POP bc        
    4092 : c5          PUSH bc       
    4093 : b9          CP A,c        
    4094 : 28 06       JR z,(PC+06H) 
    4096 : 0c          INC c         
    4097 : 10 fa       DJNZ (PC+faH) 
    4099 : c1          POP bc        
    409a : 18 e7       JR (PC+e7H)   
    409c : c1          POP bc        
    409d : e1          POP hl        
    409e : 77          LD (HL),a     
    409f : c9          RET           

KYBD:
/*
KYBD is a routine which sets up machine control of
the keyboard such that only the eight key
codes from code 29 and the eight key codes
from code 38 are acceptable entries. Any other
key depression is ignored. 
*/
    40a0 : 01 1d 08    LD bc,081dH   
    40a3 : cd 82 40    CALL (4082H)  
    40a6 : 2b          DEC hl        
    40a7 : 0e 26       LD c,26H      
    40a9 : cd 82 40    CALL (4082H)  
    40ac : 23          INC hl        
    40ad : 7e          LD a,(HL)     
    40ae : d6 1c       SUB 1cH       
    40b0 : 47          LD b,a        
    40b1 : 0e 0b       LD c,0bH      
    40b3 : af          XOR A,a       
    40b4 : 81          ADD A,c       
    40b5 : 10 fd       DJNZ (PC+fdH) 
    40b7 : c6 61       ADD A,61H     
    40b9 : 2b          DEC hl        
    40ba : 96          SUB A,(HL)   

/*
Move produces a list of all legal moves
available to the piece under consideration.
*/
MOVE:
!? This address matches 40273, the move routine in magazine, but the code is expected to be:
      LD A E     123
      ADD A (HL) 134
      PUSH AF    245
      PUSH HL    229
      PUSH BC    197
      CP N       254 63
      JP C DIS   56 38


STR:
/*
STR: this routine takes the board address
and determines whether the contents
are: different from the current mover colour;
empty; the board surround or the same
colour as the current mover.
*/
    40bb : 4f          LD c,a        
    40bc : 69          LD l,c        
    40bd : 26 43       LD h,43H      
    40bf : 7e          LD a,(HL)     
    40c0 : 06 01       LD b,01H      
    40c2 : e6 7f       AND 7fH       
    40c4 : fe 00       CP 00H        
    40c6 : 28 14       JR z,(PC+14H) 
    40c8 : 04          INC b         
    40c9 : fe 76       CP 76H        
    40cb : 28 0f       JR z,(PC+0fH) 
    40cd : fe 27       CP 27H        
    40cf : 38 0b       JR c,(PC+0bH) 
    40d1 : 7e          LD a,(HL)     
    40d2 : 04          INC b         
    40d3 : 2e 37       LD l,37H      
    40d5 : 86          ADD A,(HL)    
    40d6 : cb 7f       BIT 7,a       
    40d8 : 28 02       JR z,(PC+02H) 
    40da : 06 00       LD b,00H      
    40dc : 78          LD a,b        
    40dd : 69          LD l,c        
    40de : c9          RET           

TABLES: (decimal)
16607
defb 1 11 -1 -11 -10 -12 12 10
16615 
defb 13 -13 21 -21 23 -23 -9 9
16623 
defb 11 10 12
16626 
defb 54 55 39 51 53

  

PIECE:
/*
Piece: this sets up pointers to possible move
tables and number of steps and directions.
*/
    40f7 : af          XOR A,a       
    40f8 : 32 46 40    LD (4046H),A  
    40fb : 7e          LD a,(HL)     
    40fc : e6 7f       AND 7fH       
    40fe : fe 35       CP 35H        
    4100 : 28 4f       JR z,(PC+4fH) 
    4102 : 0e 01       LD c,01H      
    4104 : 06 08       LD b,08H      
    4106 : 21 e7 40    LD hl,40e7H   
    4109 : fe 33       CP 33H        
    410b : 28 16       JR z,(PC+16H) 
    410d : 2e df       LD l,dfH      
    410f : fe 30       CP 30H        
    4111 : 28 10       JR z,(PC+10H) 
    4113 : 48          LD c,b        
    4114 : fe 36       CP 36H        
    4116 : 28 0b       JR z,(PC+0bH) 
    4118 : 06 04       LD b,04H      
    411a : fe 37       CP 37H        
    411c : 28 05       JR z,(PC+05H) 
    411e : 2e e3       LD l,e3H      
    4120 : fe 27       CP 27H        
    4122 : c0          RET nz        


MOVE:
/*
Move produces a list of all legal moves
available to the piece under consideration.
*/
    4123 : 7b          LD a,e        
    4124 : 86          ADD A,(HL)    
    4125 : f5          PUSH af       
    4126 : e5          PUSH hl       
    4127 : c5          PUSH bc       
    4128 : fe 3f       CP 3fH        
    412a : 38 1e       JR c,(PC+1eH) 
    412c : fe 94       CP 94H        
    412e : 30 1a       JR nc,(PC+1aH)
    4130 : cd bb 40    CALL (40bbH)  
    4133 : fe 02       CP 02H        
    4135 : 30 13       JR nc,(PC+13H)
    4137 : f5          PUSH af       
    4138 : cd 8d 42    CALL (428dH)  
    413b : f1          POP af        
    413c : fe 00       CP 00H        
    413e : 28 0a       JR z,(PC+0aH) 
    4140 : c1          POP bc        
    4141 : e1          POP hl        
    4142 : 79          LD a,c        
    4143 : fe 01       CP 01H        
    4145 : 28 05       JR z,(PC+05H) 
    4147 : f1          POP af        
    4148 : 18 da       JR (PC+daH)   
    414a : c1          POP bc        
    414b : e1          POP hl        
    414c : f1          POP af        
    414d : 23          INC hl        
    414e : 10 d3       DJNZ (PC+d3H) 
    4150 : c9          RET           


PAWN:
/*
Pawn produces a list of all possible legal
moves including initial double moves.
*/
    4151 : 7e          LD a,(HL)     
    4152 : e6 80       AND 80H       
    4154 : 21 e4 40    LD hl,40e4H   
    4157 : 20 02       JR nz,(PC+02H)
    4159 : 2e f1       LD l,f1H      
    415b : 16 03       LD d,03H      
    415d : 7b          LD a,e        
    415e : 86          ADD A,(HL)    
    415f : e5          PUSH hl       
    4160 : f5          PUSH af       
    4161 : fe 3f       CP 3fH        
    4163 : 38 20       JR c,(PC+20H) 
    4165 : fe 94       CP 94H        
    4167 : 30 1c       JR nc,(PC+1cH)
    4169 : cd bb 40    CALL (40bbH)  
    416c : fe 00       CP 00H        
    416e : 28 1c       JR z,(PC+1cH) 
    4170 : fe 01       CP 01H        
    4172 : 20 11       JR nz,(PC+11H)
    4174 : 7a          LD a,d        
    4175 : fe 01       CP 01H        
    4177 : 20 0c       JR nz,(PC+0cH)
    4179 : cd 8d 42    CALL (428dH)  
    417c : 7b          LD a,e        
    417d : fe 52       CP 52H        
    417f : 38 13       JR c,(PC+13H) 
    4181 : fe 7e       CP 7eH        
    4183 : 30 0f       JR nc,(PC+0fH)
    4185 : f1          POP af        
    4186 : e1          POP hl        
    4187 : 2b          DEC hl        
    4188 : 15          DEC d         
    4189 : 20 d2       JR nz,(PC+d2H)
    418b : c9          RET           
    418c : 7a          LD a,d        
    418d : fe 01       CP 01H        
    418f : c4 8d 42    CALL nz,428dH 
    4192 : 18 f1       JR (PC+f1H)   
    4194 : f1          POP af        
    4195 : e1          POP hl        
    4196 : 5f          LD e,a        
    4197 : 18 c5       JR (PC+c5H)   


SCORE:
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
    4199 : e5          PUSH hl       
    419a : c5          PUSH bc       
    419b : d5          PUSH de       
    419c : e5          PUSH hl       
    419d : c5          PUSH bc       
    419e : 55          LD d,l        
    419f : 21 40 40    LD hl,4040H   
    41a2 : cd 24 07    CALL (0724H)  
    41a5 : cd 0a 43    CALL (430aH)  
    41a8 : 78          LD a,b        
    41a9 : 84          ADD A,h       
    41aa : 4f          LD c,a        
    41ab : f1          POP af        
    41ac : cd 0a 43    CALL (430aH)  
    41af : e1          POP hl        
    41b0 : cd 18 43    CALL (4318H)  
    41b3 : 30 01       JR nc,(PC+01H)
    41b5 : 80          ADD A,b       
    41b6 : 4f          LD c,a        
    41b7 : e1          POP hl        
    41b8 : d1          POP de        
    41b9 : 5e          LD e,(HL)     
    41ba : 72          LD (HL),d     
    41bb : e5          PUSH hl       
    41bc : d5          PUSH de       
    41bd : cd 18 43    CALL (4318H)  
    41c0 : 30 01       JR nc,(PC+01H)
    41c2 : 90          SUB A,b       
    41c3 : f5          PUSH af       
    41c4 : cd f7 42    CALL (42f7H)  
    41c7 : cd 01 42    CALL (4201H)  
    41ca : c1          POP bc        
    41cb : 30 02       JR nc,(PC+02H)
    41cd : 04          INC b         
    41ce : 04          INC b         
    41cf : d1          POP de        
    41d0 : e1          POP hl        
    41d1 : 73          LD (HL),e     
    41d2 : e1          POP hl        
    41d3 : cd fa 42    CALL (42faH)  
    41d6 : cd 18 43    CALL (4318H)  
    41d9 : 30 01       JR nc,(PC+01H)
    41db : 05          DEC b         
    41dc : cd fa 42    CALL (42faH)  
    41df : cd f7 42    CALL (42f7H)  
    41e2 : 78          LD a,b        
    41e3 : 21 3c 40    LD hl,403cH   
    41e6 : 77          LD (HL),a     
    41e7 : eb          EX DE,HL      
    41e8 : 21 41 40    LD hl,4041H   
    41eb : be          CP A,(HL)     
    41ec : d8          RET c         
    41ed : 01 05 00    LD bc,0005H   
    41f0 : 18 0b       JR (PC+0bH)   


SHIFT:
/*
 Shift moves the current move list to a safe
position whilst Check is being evaluated, and
then recovers the move list on completion. It is
also used to shift the best move so far up into
the move list.*/
    41f2 : 21 63 40    LD hl,4063H   
    41f5 : 11 46 40    LD de,4046H   
    41f8 : 01 1c 00    LD bc,TEST_SP 
    41fb : 38 01       JR c,(PC+01H) 
    41fd : eb          EX DE,HL      
    41fe : ed b0       LDIR          
    4200 : c9          RET           


CHK:
/*
CHECK locates current mover's Kings and stores the
position in the attack register.
*/
    4201 : 3a 37 43    LD A,(4337H)  
    4204 : c6 30       ADD A,30H     
    4206 : 21 3e 43    LD hl,433eH   
    4209 : 47          LD b,a        
    420a : ed b1       CPIR          
    420c : 2b          DEC hl        
    420d : 22 80 40    LD (4080H),HL 


SQUARE_ATACK:
SQ_AT:
/*
determines whether the opposition can attack
the square in the attack register.
*/
    4210 : 06 56       LD b,56H      
    4212 : 21 3e 43    LD hl,433eH   
    4215 : 23          INC hl        
    4216 : e5          PUSH hl       
    4217 : c5          PUSH bc       
    4218 : 5d          LD e,l        
    4219 : cd bf 40    CALL (40bfH)  
    421c : fe 00       CP 00H        
    421e : 20 19       JR nz,(PC+19H)
    4220 : cd f7 42    CALL (42f7H)  
    4223 : 6b          LD l,e        
    4224 : cd f7 40    CALL (40f7H)  
    4227 : cd f7 42    CALL (42f7H)  
    422a : cd 82 42    CALL (4282H)  
    422d : 28 0a       JR z,(PC+0aH) 
    422f : 2a 80 40    LD HL,(4080H) 
    4232 : bd          CP A,l        
    4233 : 20 f5       JR nz,(PC+f5H)
    4235 : c1          POP bc        
    4236 : e1          POP hl        
    4237 : 37          SCF           
    4238 : c9          RET           
    4239 : c1          POP bc        
    423a : e1          POP hl        
    423b : 10 d8       DJNZ (PC+d8H) 
    423d : a7          AND A,a       
    423e : c9          RET           


DRIVER:
/*
Driver Main control logic, uses all the
other subroutines to provide program control.
*/
    423f : 06 05       LD b,05H      
    4241 : 3e 08       LD a,08H      
    4243 : 21 9f 43    LD hl,439fH   
    4246 : 23          INC hl        
    4247 : 77          LD (HL),a     
    4248 : 10 fc       DJNZ (PC+fcH) 
    424a : cd a0 40    CALL (40a0H)  
    424d : fe 03       CP 03H        
    424f : 20 ee       JR nz,(PC+eeH)
    4251 : 22 07 40    LD (4007H),HL 
    4254 : 5d          LD e,l        
    4255 : cd f7 40    CALL (40f7H)  
    4258 : 21 a1 43    LD hl,43a1H   
    425b : cd a0 40    CALL (40a0H)  
    425e : fe 02       CP 02H        
    4260 : eb          EX DE,HL      
    4261 : 30 dc       JR nc,(PC+dcH)
    4263 : cd 82 42    CALL (4282H)  
    4266 : 28 d7       JR z,(PC+d7H) 
    4268 : b9          CP A,c        
    4269 : 20 f8       JR nz,(PC+f8H)
    426b : cd ff 42    CALL (42ffH)  
    426e : d9          EXX           
    426f : cd 01 42    CALL (4201H)  
    4272 : d9          EXX           
    4273 : 38 08       JR c,(PC+08H) 
    4275 : cd eb 42    CALL (42ebH)  
    4278 : cd 96 42    CALL (4296H)  
    427b : 18 c2       JR (PC+c2H)   
    427d : 70          LD (HL),b     
    427e : 79          LD a,c        
    427f : 12          LD (DE),A     
    4280 : 18 f9       JR (PC+f9H)   


TEST LIST:
/*
TestList: tests to see if there are any moves
in the move list.
*/
    4282 : 21 46 40    LD hl,4046H   
    4285 : 35          DEC (HL)      
    4286 : 7e          LD a,(HL)     
    4287 : 3c          INC a         
    4288 : c8          RET z         
    4289 : 85          ADD A,l       
    428a : 6f          LD l,a        
    428b : 7e          LD a,(HL)     
    428c : c9          RET           


ALIST:
/*
AddList: adds to the current
legal move list another entry on the end.
*/
    428d : 21 46 40    LD hl,4046H   
    4290 : 34          INC (HL)      
    4291 : 7e          LD a,(HL)     
    4292 : 85          ADD A,l       
    4293 : 6f          LD l,a        
    4294 : 71          LD (HL),c     
    4295 : c9          RET           


MPSCAN:
/*
MPScan scans the board for computer
pieces and, using move and score, determines
all legal moves and saves the best. INC
determines whether a square is being attacked.
*/
    4296 : af          XOR A,a       
    4297 : 32 41 40    LD (4041H),A  
    429a : 06 56       LD b,56H      
    429c : 21 3e 43    LD hl,433eH   
    429f : 23          INC hl        
    42a0 : e5          PUSH hl       
    42a1 : c5          PUSH bc       
    42a2 : 5d          LD e,l        
    42a3 : cd bf 40    CALL (40bfH)  
    42a6 : fe 03       CP 03H        
    42a8 : 20 29       JR nz,(PC+29H)
    42aa : 6b          LD l,e        
    42ab : 22 07 40    LD (4007H),HL 
    42ae : cd f7 40    CALL (40f7H)  
    42b1 : cd 82 42    CALL (4282H)  
    42b4 : 28 1d       JR z,(PC+1dH) 
    42b6 : 5f          LD e,a        
    42b7 : 16 43       LD d,43H      
    42b9 : cd ff 42    CALL (42ffH)  
    42bc : d9          EXX           
    42bd : a7          AND A,a       
    42be : cd f2 41    CALL (41f2H)  
    42c1 : cd 01 42    CALL (4201H)  
    42c4 : d9          EXX           
    42c5 : 70          LD (HL),b     
    42c6 : 79          LD a,c        
    42c7 : 12          LD (DE),A     
    42c8 : 38 03       JR c,(PC+03H) 
    42ca : cd 99 41    CALL (4199H)  
    42cd : 37          SCF           
    42ce : cd f2 41    CALL (41f2H)  
    42d1 : 18 de       JR (PC+deH)   
    42d3 : c1          POP bc        
    42d4 : e1          POP hl        
    42d5 : 10 c8       DJNZ (PC+c8H) 
    42d7 : 3a 41 40    LD A,(4041H)  
    42da : fe 00       CP 00H        
    42dc : 28 fe       JR z,(PC+feH) 
    42de : 21 45 40    LD hl,4045H   
    42e1 : 7e          LD a,(HL)     
    42e2 : 2b          DEC hl        
    42e3 : 2b          DEC hl        
    42e4 : 5e          LD e,(HL)     
    42e5 : 16 43       LD d,43H      
    42e7 : 12          LD (DE),A     
    42e8 : 2b          DEC hl        
    42e9 : 6e          LD l,(HL)     
    42ea : 62          LD h,d        
    42eb : cb 45       BIT 0,l       
    42ed : 36 80       LD (HL),80H   
    42ef : 28 02       JR z,(PC+02H) 
    42f1 : 36 00       LD (HL),00H   
    42f3 : cd f7 42    CALL (42f7H)  
    42f6 : c9          RET           


CHGMV:
    42f7 : 21 37 43    LD hl,4337H   
    42fa : 7e          LD a,(HL)     
    42fb : c6 80       ADD A,80H     
    42fd : 77          LD (HL),a     
    42fe : c9          RET           


PMOVE:
    42ff : 2a 07 40    LD HL,(4007H) 
    4302 : 1a          LD A,(DE)     
    4303 : 4f          LD c,a        
    4304 : 7e          LD a,(HL)     
    4305 : 36 00       LD (HL),00H   
    4307 : 12          LD (DE),A     
    4308 : 47          LD b,a        
    4309 : c9          RET           


PSC:
/*
PSC gives a score to a chess piece Q(5),
R(4), B(3), N(2), P(1).
*/
    430a : e6 7f       AND 7fH       
    430c : 21 f2 40    LD hl,40f2H   
    430f : 06 05       LD b,05H      
    4311 : be          CP A,(HL)     
    4312 : c8          RET z         
    4313 : 23          INC hl        
    4314 : 10 fb       DJNZ (PC+fbH) 
    4316 : 78          LD a,b        
    4317 : c9          RET           

INC:
    4318 : 7d          LD a,l        
    4319 : d9          EXX           
    431a : 32 80 40    LD (4080H),A  
    431d : cd 10 42    CALL (4210H)  
    4320 : d9          EXX           
    4321 : 79          LD a,c        
    4322 : c9          RET 


JUNK:?!?!?!?
4323 : 76          HALT          
4324 : 00          nop           
4325 : 02          LD (BC),A     
4326 : 02          LD (BC),A     
4327 : 00          nop           
4328 : e4 76 00    CALL po,0076H 
432b : 03          INC bc        
432c : 04          INC b         
432d : 00          nop           
432e : f9          LD SP,HL      
432f : d4 3d 76    CALL nc,763dH 
4332 : 76          HALT          
4333 : 76          HALT          
4334 : 76          HALT          
4335 : 76          HALT          
4336 : 76          HALT          
4337 : 80          ADD A,b       
4338 : 08          EX AF,AF'
4339 : a9          XOR A,c       
433a : b7          OR A,a        
433b : ad          XOR A,l       
433c : 76          HALT          
433d : 1d          DEC e         
433e : 08          EX AF,AF'
433f : 37          SCF           
4340 : 33          INC sp        
4341 : 27          DAA           
4342 : 30 36       JR nc,(PC+36H)
4344 : 27          DAA           
4345 : 33          INC sp        
4346 : 37          SCF           
4347 : 76          HALT          
4348 : 1e 08       LD e,08H      
434a : 35          DEC (HL)      
434b : 35          DEC (HL)      
434c : 35          DEC (HL)      
434d : 35          DEC (HL)      
434e : 80          ADD A,b       
434f : 35          DEC (HL)      
4350 : 35          DEC (HL)      
4351 : 35          DEC (HL)      
4352 : 76          HALT          
4353 : 1f          RRA           
4354 : 08          EX AF,AF'
4355 : 00          nop           
4356 : 80          ADD A,b       
4357 : 00          nop           
4358 : 80          ADD A,b       
4359 : 35          DEC (HL)      
435a : 80          ADD A,b       
435b : 00          nop           
435c : 80          ADD A,b       
435d : 76          HALT          
435e : 20 08       JR nz,(PC+08H)
4360 : 80          ADD A,b       
4361 : 00          nop           
4362 : 80          ADD A,b       
4363 : 00          nop           
4364 : 80          ADD A,b       
4365 : 00          nop           
4366 : 80          ADD A,b       
4367 : 00          nop           
4368 : 76          HALT          
4369 : 21 08 00    LD hl,ERROR_1 
436c : 80          ADD A,b       
436d : 00          nop           
436e : 80          ADD A,b       
436f : 00          nop           
4370 : 80          ADD A,b       
4371 : 00          nop           
4372 : 80          ADD A,b       
4373 : 76          HALT          
4374 : 22 08 80    LD (8008H),HL 
4377 : 00          nop           
4378 : 80          ADD A,b       
4379 : 00          nop           
437a : 80          ADD A,b       
437b : 00          nop           
437c : 80          ADD A,b       
437d : 00          nop           
437e : 76          HALT          
437f : 23          INC hl        
4380 : 08          EX AF,AF'
4381 : b5          OR A,l        
4382 : b5          OR A,l        
4383 : b5          OR A,l        
4384 : b5          OR A,l        
4385 : b5          OR A,l        
4386 : b5          OR A,l        

4387 : b5          OR A,l        
4388 : b5          OR A,l        
4389 : 76          HALT          
438a : 24          INC h         
438b : 08          EX AF,AF'
438c : b7          OR A,a        
438d : b3          OR A,e        
438e : a7          AND A,a       
438f : b0          OR A,b        
4390 : b6          OR A,(HL)     
4391 : a7          AND A,a       
4392 : b3          OR A,e        
4393 : b7          OR A,a        
4394 : 76          HALT          
4395 : 08          EX AF,AF'
4396 : 08          EX AF,AF'
4397 : 2d          DEC l         
4398 : 2c          INC l         
4399 : 2b          DEC hl        
439a : 2a 29 28    LD HL,(2829H) 
439d : 27          DAA           
439e : 26 76       LD h,76H      
43a0 : 08          EX AF,AF'
43a1 : 08          EX AF,AF'
43a2 : 08          EX AF,AF'
43a3 : 08          EX AF,AF'
43a4 : 08          EX AF,AF'
43a5 : 76          HALT          
43a6 : 76          HALT          
43a7 : 76          HALT          
43a8 : 76          HALT          
43a9 : 76          HALT          
43aa : 76          HALT          
43ab : 76          HALT          
43ac : 76          HALT          
43ad : 76          HALT          
43ae : 76          HALT          
43af : 7d          LD a,l        
43b0 : 8f          ADC A,a       
43b1 : 04          INC b         
43b2 : 7e          LD a,(HL)     
43b3 : 00          nop           
43b4 : 00          nop           
43b5 : 80          ADD A,b       
43b6 : 00          nop           
43b7 : 00          nop          
