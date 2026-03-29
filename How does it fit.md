# In conclusion...

So, after all of this, what did I discover about the code? How did David get 1K chess into 1K?

Here are some highlights...

## The big things

* The screen _is_ the board state. There is no separate data structure holding the pieces, or the current player
* Because of this, when examining possible moves it genuinely makes them on the board ($42b9) which gives the impression that the machine is thinking. In reality, it's saving memory
* The screen is saved with the program, so no code is needed to generate/render it
* Every major piece uses the same loop to determine valid moves
* The board is between memory locations $433F and $4393, therefore it never crosses a MSB boundary meaning all computations can be done with a single (LSB) byte, and the list of possible moves needs only 1 byte per move. This is only possible because the display is "collapsed" with each row taking 11 bytes, rather than 32
* The game hangs on completion and must be reloaded. Therefore no restart code is needed


## The small things

* When determining the possible moves, the pieces are checked in a specific order that doesn't need the variables to be changed more than necessary ($40f7)
* The same "pawns move 2 at start" logic is handled identically for white and black pawns ($417d). It _feels_ wrong that the black pawn could move two spaces when on the same row as the white pawns, but it's fine. (See code comments)
* Pawns moving 2 is handled by checking for a single move - twice
* Routines are ordered so that one function falls through to the next one, without needing a CALL or JR instruction (e.g. CHK and SQUARE_ATACK, KYBD and STR, PIECE and MOVE)
* It checks 86 squares - which includes the board edges - for an opponent piece. It's less code that setting up two separate loops, or explicitly ignoring the edge. We just process a little extra and handle the "this is not an opponent piece" in the usual way
* Doesn't calculate whether the human puts themselves in check. It makes the move, and _then_ checks, undoing to the move if necessary. This allows re-use of the "is in check" code, without writing a new "will it be in check" method.
* The code jumps 11 places forwards in memory ($41f0) to re-use an LDIR call to copy some data. It saves 1 byte.


## The most interesting things

* An 8 byte table holds the movement patterns for the king, queen, rook, bishop, and black pawn ($40df)
* This table is specially ordered to facilitate all five pieces ($40df)
* The scoring of material is 5,4,3,2, and 1 to save an extra table ($430a)
* The order of the pawn move offsets places the capture moves together so only one check is needed ($40e2)
* The final pawn move checked is forwards. It can re-run the loop to check a second time for opening pawn moves
* Repairing the board, after a piece has moved, uses 8 bytes. It draws a black square, then over-writes it with white if necessary (saving a jump). It also doesn't need to check the row, because there are exactly 3 extra bytes per row, allowing the "is it even" code to auto-adjust on each row.
* At $41a2 we call a 7-byte routine in ROM ($0724) to store BC & DE into memory. This routine is just part of an existing block of code, that we jump into part-way through. But it saves 4 bytes.



## The Z80/ZX81 specific things

* Uses `LD c,b` instead of `LD b,08H` ($4113) to save one instruction byte
* Uses `RET nz` to save a comparare-then-jump pair
* `LDIR` copies between the move list and it's backup, in the same routine. It just reverses the source and destination registers with `EX DE,HL`
* Multiple single byte instructions, ordered appropriately ($4282)
* `EXX` exchanges three register pairs (BC, DE, HL) with a complete set of shadow registers. It's quicker and shorter than pushing to a stack, or storing elsewhere
* `XOR A,A` is the same as A=0, but in fewer bytes
* `INC B`, called twice, uses 2 bytes. `ADD B,2` uses 3
* Sets HL to point to the first movement table, but then only changes L to point to the next one
* Keeps data in registers for as long as possible. e.g. E holds the square offset
* Calls the code with `RAND USR X` since the pre-initialised variable uses fewer bytes that the literal `16959`

