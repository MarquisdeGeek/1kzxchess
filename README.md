# 1K ZX Chess - the rebuild

The original code was 672 bytes, and comprises 390 instructions with 24 bytes of lookup tables and 45 bytes of working memory.

This is a complete documentation and explanation of the code, along with an analysis of the memory-saving techniques used. There is also a version that you can rebuild, should you wish to add the missing features!

So what's here?


## Unfold - how I came to understand the code

Working from the machine code:

* 0 - Original.asm : taken from https://users.ox.ac.uk/~uzdm0006/scans/1kchess/
* 1 - Corrected.asm : disassembled using https://em.ulat.es/machines/SinclairZX81/
* 2 - Labelled.asm : combined 1 with the labels from 0. Added entry/exit conditions for each method
* 3 - Commented.asm : line-by-line analysis

# src - buildable versions

Starting from the commented source:

* Use local labels
* Improved labels, generally
* Switch `XOR a,a` to `XOR a`, etc, so sjasmplus generates the shorter instructions
* Added enumerations for STR_DETERMINE_SQUARE_CONTENTS
* Used character constants for _K, _Q etc



# Basic things

* There are 11 bytes per row
* There is a single byte at the end of each row - it is 118, not a CR or LF
* The ZX81 does not use ASCII, so the character codes for the pieces are not obvious. K is 48 ($32) for example.
* Knights are represented by 'N' to avoid confusion with 'K'ings.
* White pieces are shown with normal text, while black are inverse. The codes differ only insomuch as black has the MSB (0x80) set. This is used extensively.
* My disass produced `CP A,C` for comparison, although A is implicit and sjasmplus consequently treated it as a two byte instruction. (See also SUB A,(HL)) Consequently, I need to change these instructions.

