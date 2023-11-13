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
    stw zero,CP_VALID(zero)

;Initialisation de la partie
    main_init_game:
        call wait
        call init_game

;Main de base qui recupere les input et adapte le jeu
    main_get_input:
        call wait
        call get_input

        addi t0,zero,BUTTON_CHECKPOINT
        beq v0,t0,main_cp

        call hit_test
        addi a0,v0,0

        addi t0,zero,RET_ATE_FOOD
        beq v0,t0,main_ate_food

        addi t0,zero,RET_COLLISION
        beq v0,t0,main_init_game

        call move_snake

        br display

;Main quand le serpent a mangé un fruit : update le score,create_food
    main_ate_food:
        ldw t0, SCORE(zero)
        addi t0,t0,1
        stw t0, SCORE(zero)
        call display_score
        call move_snake
        call create_food

        call save_checkpoint

        beq v0,zero,display

        br display

;Main si le boutton Checkpoint est appuyé
    main_cp:
        call restore_checkpoint    

        beq v0,zero,main_get_input
        br blink

;Permet de display le le jeu avec blink qui ne s'execute pas tout le temps
    blink :
        call blink_score

    display:
        call clear_leds
        call draw_array

    br main_get_input
;Wait procedure pour pouvoir jouer sur le GECKO
wait :
    addi t4, zero, 1    ;t4 = 1
    slli t5, t4, 22     ;t5 = 2 puissance 22
    continue : 
        beq t5, zero, exit
        sub t5, t5, t4
        br continue

    exit : 
        ret
; END: main
   
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
    ldw t0,digit_map(zero)
    stw t0,SEVEN_SEGS(zero)
    stw t0,4 + SEVEN_SEGS(zero)

    ldw t0,SCORE(zero)
    addi t1,zero,0  ;representera les dizaines
    addi t2,zero,10

    blt t0,t2,show_score

    modulo10:
        addi t1,t1,1
        sub t0,t0,t2
        bge t0,t2,modulo10

    show_score:
        slli t1,t1,2
        ldw t1, digit_map(t1)
        stw t1, 8 + SEVEN_SEGS(zero)
        slli t0,t0,2
        ldw t0, digit_map(t0)
        stw t0, 12 + SEVEN_SEGS(zero)

    ret    

; END: display_score


; BEGIN: init_game
init_game:
	addi t0,zero,0
    addi t1,zero,NB_CELLS
    slli t1,t1,2

    clear_GSA:
        stw zero,GSA(t0)
        addi t0,t0,4
        bne t0,t1,clear_GSA

	addi t0, zero, 4			
	stw t0, GSA(zero)			
	stw zero, HEAD_X(zero)			
	stw zero, HEAD_Y(zero)			
	stw zero, TAIL_X(zero)			
	stw zero, TAIL_Y(zero)			
	stw zero, SCORE(zero)		

	addi sp, sp, -4
	stw ra, 0(sp)				
    call create_food
	ldw ra, 0(sp)				
	addi sp, sp, 4

	addi sp, sp, -4
	stw ra, 0(sp)				
    call clear_leds
	ldw ra, 0(sp)				
	addi sp, sp, 4

	addi sp, sp, -4
	stw ra, 0(sp)				
    call draw_array
	ldw ra, 0(sp)				
	addi sp, sp, 4

	addi sp, sp, -4
	stw ra, 0(sp)				
    call display_score
	ldw ra, 0(sp)				
	addi sp, sp, 4
	
	ret
; END: init_game


; BEGIN: create_food
create_food:
    addi t0,zero,0xFF   ;mask du dernier byte
    ldw t1,RANDOM_NUM(zero)   ;load le nombre random
    and t0,t1,t0    ;recupere la valeur random

    addi t1,zero,NB_CELLS     ;limite du GSA en index

    bge t0,t1,create_food   ;si depasse la limite, on recommence
    
    slli t0,t0,2    ;x4 l'adresse random car on est avec des word
    ldw t2,GSA(t0)
    bne t2,zero,create_food ;si le pixel n'est pas libre, on recommence

    addi t2,zero,FOOD
    stw t2,GSA(t0)  ;met le pixel random du GSA a 5 (FOOD)

    ret
; END: create_food


; BEGIN: hit_test
hit_test:
    ldw t1,HEAD_X(zero)
    ldw t2,HEAD_Y(zero)

    slli t3, t1, 3
    add t3, t2, t3  ;addresse dans le GSA calculee
    slli t3, t3, 2  ;multiplication par 4 car on travaille avec des words dans le GSA
    ldw t4, GSA(t3) ;recupere la valeur de la head
    
    addi t0,zero,DIR_RIGHT
    beq t4,t0,right_hit
    addi t0,zero,DIR_LEFT
    beq t4,t0,left_hit
    addi t0,zero,DIR_UP
    beq t4,t0,up_hit
    addi t0,zero,DIR_DOWN
    beq t4,t0,down_hit

    right_hit : 
        addi t3, zero, NB_COLS - 1
        beq t1, t3, exit_game_end
        addi t1,t1,1
        br suite_hit_test

    left_hit : 
        beq t1, zero, exit_game_end
        addi t1,t1,-1
        br suite_hit_test

    up_hit : 
        beq t2, zero, exit_game_end
        addi t2,t2,-1
        br suite_hit_test

    down_hit : 
        addi t3, zero, NB_ROWS - 1
        beq t2, t3, exit_game_end
        addi t2,t2,1
        br suite_hit_test

    suite_hit_test : 

        slli t3, t1, 3
        add t3, t2, t3  ;addresse dans le GSA calculee
        slli t3, t3, 2  ;multiplication par 4 car on travaille avec des words dans le GSA
        ldw t4, GSA(t3) ;recupere la valeur de la head

        addi t6, zero, FOOD       ;t6 = 5

        beq t4, t6, exit_score_increment
        beq t4, zero, exit_no_collision
        br exit_game_end

    exit_score_increment : 
        addi v0, zero, RET_ATE_FOOD
        ret

    exit_no_collision : 
        addi v0, zero, 0
        ret

    exit_game_end : 
        addi v0, zero, RET_COLLISION
        ret

; END: hit_test


; BEGIN: get_input
get_input:
    ldw t0,4 + BUTTONS(zero)   ;edgecapture
    stw zero,4 + BUTTONS(zero)  ;clear edgecapture

    andi t5,t0,0b10000        ;mask de checkpoint
    srli t5,t5,4
    andi t4,t0,0b1000   ;mask de right
    srli t4,t4,3
    andi t3,t0,0b100    ;mask de down
    srli t3,t3,2
    andi t2,t0,0b10     ;mask de up
    srli t2,t2,1
    andi t1,t0,1      ;mask de left

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
    addi t0,zero,-1
    addi t1,zero,-1

    loop_x: ;boucle des x
        addi t0,t0,1
        addi t2,zero,NB_COLS
        beq t0,t2,end

        loop_y :    ;boucle des y
            addi t1,t1,1
            addi t6,zero,NB_ROWS
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
            addi t1,zero,-1
            br loop_x

    end :
        ret


; END: draw_array


; BEGIN: move_snake
move_snake:

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
        addi t1,t1,-1
        stw t1,HEAD_X(zero)
        br suite
    up_head:
        addi t2,t2,-1
        stw t2,HEAD_Y(zero)
        br suite
    down_head:
        addi t2,t2,1
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
                addi t1,t1,-1
                stw t1,TAIL_X(zero)
                ret
            up_tail:
                addi t2,t2,-1
                stw t2,TAIL_Y(zero)
                ret
            down_tail:
                addi t2,t2,1
                stw t2,TAIL_Y(zero)
                ret

; END: move_snake

memory_copy : 

    addi t0,zero,-1
    addi t1,zero,-1

    loop_x_mem: ;boucle des x
        addi t0,t0,1
        addi t2,zero,NB_ROWS
        beq t0,t2,end_mem

        loop_y_mem :    ;boucle des y
            addi t1,t1,1
            addi t6,zero,NB_COLS
            beq t1,t6,reset_y_mem       ;t0 (x) et t1 (y) parcourt tout le GSA

            slli t3, t0, 3
            add t3, t3, t1  ;addresse dans le GSA calculee
            slli t3, t3, 2  ;multiplication par 4 car on travaille avec des words dans le GSA
            add t4, t3, a2 
            ldw t4, 0(t4)      ;recupere la valeur du GSA a (x,y)

            add t5, t3, a3
            stw t4, 0(t5)
			br loop_y_mem

        reset_y_mem :   ;met a jour le y si on arrive au bout d'une colonne 
            addi t1,zero,-1
            br loop_x_mem
    end_mem :
        ret

; BEGIN: save_checkpoint
save_checkpoint:
    ldw t6, SCORE(zero)
    addi t7, zero, 10
    beq t6, zero, no_save
    save :
        bge t6, t7, decrementer
        beq t6, zero, multiple_dix
        no_save :
            addi v0, zero, 0
            ret

        decrementer : 
            addi t6, t6, -10
            br save

        multiple_dix : 
            addi v0, zero, 1
            stw v0, CP_VALID(zero)

            addi a2, zero, GSA
            addi a3, zero, CP_GSA
            
            addi sp, sp, -4
			stw ra, 0(sp)
            call memory_copy
			ldw ra, 0(sp)
			addi sp, sp, 4

            ret

        
; END: save_checkpoint


; BEGIN: restore_checkpoint
restore_checkpoint:
    ldw t0, CP_VALID(zero)
    beq t0, zero, cp_invalid

    addi a2, zero, CP_GSA
    addi a3, zero, GSA


    addi sp, sp, -4
	stw ra, 0(sp)
    call memory_copy
	ldw ra, 0(sp)
	addi sp, sp, 4

	addi v0, zero, 1
    ret

    cp_invalid : 
        addi v0, zero, 0
        ret
; END: restore_checkpoint


; BEGIN: blink_score
blink_score:
    ldw t0,digit_map(zero)
    stw t0,SEVEN_SEGS(zero)
    stw t0,4 + SEVEN_SEGS(zero)
    stw t0,8 + SEVEN_SEGS(zero)
    stw t0,12 + SEVEN_SEGS(zero)

    addi sp, sp, -4
	stw ra, 0(sp)
    call wait
	ldw ra, 0(sp)
	addi sp, sp, 4

    addi sp, sp, -4
	stw ra, 0(sp)
    call display_score
	ldw ra, 0(sp)
	addi sp, sp, 4  

    ret
; END: blink_score


digit_map:
	.word 0xFC ; 0
	.word 0x60 ; 1
	.word 0xDA ; 2
	.word 0xF2 ; 3
	.word 0x66 ; 4
	.word 0xB6 ; 5
	.word 0xBE ; 6
	.word 0xE0 ; 7
	.word 0xFE ; 8
	.word 0xF6 ; 9