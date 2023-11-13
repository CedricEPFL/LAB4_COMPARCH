;	set game state memory location
.equ    HEAD_X,         0x1000  ; Snake head's position on x
.equ    HEAD_Y,         0x1004  ; Snake head's position on y
.equ    TAIL_X,         0x1008  ; Snake tail's position on x
.equ    TAIL_Y,         0x100C  ; Snake tail's position on Y
.equ    SCORE,          0x1010  ; Score address
.equ    GSA,            0x1014  ; Game state array address

.equ    CP_VALID,       0x1200  ; Whether the checkpoint is valid.
.equ    CP_HEAD_X,      0x1204  ; Snake head's X coordinate. (Checkpoint)
.equ    CP_HEAD_Y,      0x1208  ; Snake head's Y coordinate. (Checkpoint)
.equ    CP_TAIL_X,      0x120C  ; Snake tail's X coordinate. (Checkpoint)
.equ    CP_TAIL_Y,      0x1210  ; Snake tail's Y coordinate. (Checkpoint)
.equ    CP_SCORE,       0x1214  ; Score. (Checkpoint)
.equ    CP_GSA,         0x1218  ; GSA. (Checkpoint)

.equ    LEDS,           0x2000  ; LED address
.equ    SEVEN_SEGS,     0x1198  ; 7-segment display addresses
.equ    RANDOM_NUM,     0x2010  ; Random number generator address
.equ    BUTTONS,        0x2030  ; Buttons addresses

; button state
.equ    BUTTON_NONE,    0
.equ    BUTTON_LEFT,    1
.equ    BUTTON_UP,      2
.equ    BUTTON_DOWN,    3
.equ    BUTTON_RIGHT,   4
.equ    BUTTON_CHECKPOINT,    5

; array state
.equ    DIR_LEFT,       1       ; leftward direction
.equ    DIR_UP,         2       ; upward direction
.equ    DIR_DOWN,       3       ; downward direction
.equ    DIR_RIGHT,      4       ; rightward direction
.equ    FOOD,           5       ; food

; constants
.equ    NB_ROWS,        8       ; number of rows
.equ    NB_COLS,        12      ; number of columns
.equ    NB_CELLS,       96      ; number of cells in GSA
.equ    RET_ATE_FOOD,   1       ; return value for hit_test when food was eaten
.equ    RET_COLLISION,  2       ; return value for hit_test when a collision was detected
.equ    ARG_HUNGRY,     0       ; a0 argument for move_snake when food wasn't eaten
.equ    ARG_FED,        1       ; a0 argument for move_snake when food was eaten

; initialize stack pointer
addi    sp, zero, LEDS

; main
; arguments
;     none
;
; return values
;     This procedure should never return.
main:
    ; TODO: Finish this procedure.

    ldw zero,HEAD_X(zero)
    ldw zero,HEAD_Y(zero)
    ldw zero,TAIL_X(zero)
    ldw zero,TAIL_Y(zero)
    addi t0, zero, DIR_RIGHT
    stw t0, GSA(zero)
	
	call clear_leds
	call draw_array
    loop :
        call clear_leds
        call get_input
		addi a0,zero,ARG_HUNGRY
        call move_snake
        call draw_array
        br loop


; BEGIN: clear_leds
clear_leds:
    stw zero, LEDS(zero)
    stw zero, 4 + LEDS(zero)
    stw zero, 8 + LEDS(zero)
    ret
; END: clear_leds


; BEGIN: set_pixel
set_pixel:
    addi t2, a0, LEDS           ; t0 = x + LEDS
    ldw t3, 0(t2)               ; on recupere le word lie a l'adresse [LEDS + x]
    addi t4, zero, 3            ; initialise t2 a 3
    and t5, t4, a0              ; x[4]
    slli t5, t5, 3              ; x[4]*8
    add t5, t5, a1              ; x[4]*8 + y


    addi t6, zero, 1            ; initialise t4 a 1
    sll t6, t6, t5              ; decale le 1 de x[4]*8 + y bits
    or t6, t3, t6               ; met le bit (x,y) a 1 
    stw t6, 0(t2)               ; store le word
    ret
; END: set_pixel


; BEGIN: display_score
display_score:

; END: display_score


; BEGIN: init_game
init_game:

; END: init_game


; BEGIN: create_food
create_food:

; END: create_food


; BEGIN: hit_test
hit_test:

; END: hit_test


; BEGIN: get_input
get_input:
    ldw t0,4 + BUTTONS(zero)   ;edgecapture
    stw zero,4 + BUTTONS(zero)  ;clear edgecapture

    andi t5,t0,0b10000  ;mask de checkpoint
    srli t5,t5,4
    andi t4,t0,0b1000   ;mask de right
    srli t4,t4,3
    andi t3,t0,0b100    ;mask de down
    srli t3,t3,2
    andi t2,t0,0b10     ;mask de up
    srli t2,t2,1
    andi t1,t0,1        ;mask de down

    ldw t6,HEAD_X(zero)
    ldw t7,HEAD_Y(zero)

    slli t6, t6, 3
    add t6, t7, t6  ;addresse dans le GSA calculee
    slli t6, t6, 2  ;multiplication par 4 car on travaille avec des words dans le GSA
    ldw t7, GSA(t6) ;recupere la valeur de la head

    addi t0,zero,1  ;valeur 1
    beq t5,t0,checkpoint
    beq t4,t0,right
    beq t3,t0,down
    beq t2,t0,up
    beq t1,t0,left


    addi v0,zero,0  ;le cas si c'est none
    ret

    checkpoint:
        addi v0,zero,BUTTON_CHECKPOINT
        ret

    right:
        addi v0,zero,BUTTON_RIGHT

        addi t5,zero,DIR_LEFT
        beq t7,t5,opposite_direction    ;Si la direction actuelle est left

        addi t4,zero,DIR_RIGHT          ;valeur 4
        stw t4, GSA(t6)                 ;update la direction de la head vers right
        
        ret

    down:
        addi v0,zero,BUTTON_DOWN

        addi t5,zero,DIR_UP
        beq t7,t5,opposite_direction    ;Si la direction actuelle est up

        addi t3,zero,DIR_DOWN 
        stw t3, GSA(t6)
        
        ret

    up:
        addi v0,zero,BUTTON_UP

        addi t5,zero,DIR_DOWN
        beq t7,t5,opposite_direction    ;Si la direction actuelle est down

        addi t2,zero,DIR_UP 
        stw t2, GSA(t6)
        
        ret

    left:
        addi v0,zero,BUTTON_LEFT

        addi t5,zero,DIR_RIGHT
        beq t7,t5,opposite_direction    ;Si la direction actuelle est right

        addi t1,zero,DIR_LEFT 
        stw t1, GSA(t6)
        ret

    opposite_direction :
        ret



    

; END: get_input


; BEGIN: draw_array
draw_array:

    addi t5, zero, 1

    sub t0,zero,t5
    sub t1,zero,t5

    loop_x: ;boucle des x
        addi t0,t0,1
        addi t2,zero,12
        beq t0,t2,end

        loop_y :    ;boucle des y
            addi t1,t1,1
            addi t6,zero,8
            beq t1,t6,reset_y       ;t0 (x) et t1 (y) parcourt tout le GSA

            slli t3, t0, 3
            add t3, t3, t1  ;addresse dans le GSA calculee
            slli t3, t3, 2  ;multiplication par 4 car on travaille avec des words dans le GSA
            ldw t3, GSA(t3) ;recupere la valeur du GSA a (x,y)

            beq t3,zero,loop_y  ;si il faut pas dessiner de pixel, on passe au suivant

            add a0,t0, zero
            add a1,t1, zero

			addi sp, sp, -4
			stw ra, 0(sp)
            call set_pixel
			ldw ra, 0(sp)
			addi sp, sp, 4

			br loop_y

        reset_y :   ;met a jour le y si on arrive au bout d'une colonne 
            addi t5, zero, 1
            sub t1,zero,t5
            br loop_x


    

    end :
        ret


; END: draw_array


; BEGIN: move_snake
move_snake:

    addi t5, zero, 1

    ldw t1,HEAD_X(zero)
    ldw t2,HEAD_Y(zero)

    slli t3, t1, 3
    add t3, t2, t3  ;addresse dans le GSA calculee
    slli t3, t3, 2  ;multiplication par 4 car on travaille avec des words dans le GSA
    ldw t4, GSA(t3) ;recupere la valeur de la head

    
    addi t0,zero,DIR_RIGHT
    beq t4,t0,right_head
    addi t0,zero,DIR_LEFT
    beq t4,t0,left_head
    addi t0,zero,DIR_UP
    beq t4,t0,up_head
    addi t0,zero,DIR_DOWN
    beq t4,t0,down_head


    right_head:
        addi t1,t1,1
        stw t1,HEAD_X(zero)
        br suite
        
    left_head:
        sub t1,t1,t5
        stw t1,HEAD_X(zero)
        br suite
    up_head:
        addi t2,t2,1
        stw t2,HEAD_Y(zero)
        br suite
    down_head:
        sub t2,t2,t5
        stw t2,HEAD_Y(zero)
        br suite


    suite : 
        ldw t1,HEAD_X(zero)
        ldw t2,HEAD_Y(zero)


        slli t3, t1, 3
        add t3, t2, t3      ;addresse dans le GSA calculee
        slli t3, t3, 2      ;multiplication par 4 car on travaille avec des words dans le GSA
        stw t4, GSA(t3)     ; met a jour la nouvelle head


        addi t0,zero,ARG_HUNGRY
        beq a0,t0,change_tail       ; si a0 = 0 on supprime l'ancienne tail et on set la nouvelle
        ret



        change_tail:
            ldw t1,TAIL_X(zero)
            ldw t2,TAIL_Y(zero)
            slli t3, t1, 3
            add t3, t2, t3          ;addresse dans le GSA calculee
            slli t3, t3, 2          ;multiplication par 4 car on travaille avec des words dans le GSA
            ldw t4, GSA(t3)         ;recupere la valeur de la tail
            stw zero,GSA(t3)        ;supprime l'ancienne tail


            addi t0,zero,DIR_RIGHT
            beq t4,t0,right_tail
            addi t0,zero,DIR_LEFT
            beq t4,t0,left_tail
            addi t0,zero,DIR_UP
            beq t4,t0,up_tail
            addi t0,zero,DIR_DOWN
            beq t4,t0,down_tail



            right_tail:
                addi t1,t1,1
                stw t1,TAIL_X(zero)
                ret
                
            left_tail:
                sub t1,t1,t5
                stw t1,TAIL_X(zero)
                ret
            up_tail:
                addi t2,t2,1
                stw t2,TAIL_Y(zero)
                ret
            down_tail:
                sub t2,t2,t5
                stw t2,TAIL_Y(zero)
                ret


        

; END: move_snake


; BEGIN: save_checkpoint
save_checkpoint:

; END: save_checkpoint


; BEGIN: restore_checkpoint
restore_checkpoint:

; END: restore_checkpoint


; BEGIN: blink_score
blink_score:

; END: blink_score
