

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
