title   Advent of Code - Day 1
        ; Solution to part 1

;Imports
include ..\stdutil.mac
include ..\stdutil.con

;Constants

stack_s segment para STACK
        db      200     dup('S')
stack_s ends

data_s  segment
        _input_file             db        'B:\DAY01\SAMPLE01.DAT',0
        ;_input_file            db        'B:\DAY01\INPUT01.DAT',0
        _input_file_handle      dw        0
        _input_file_char        db        0
        _direction_char         db        0
        _rot_number_buff        db        5 dup(0)
        _rot_buff_index         dw        0
        _binary_conv_total      dw        0
        _ten_pow_tab            db        1,10,100
        _hex_display_tab        db        30h,31h,32h,33h,34h,35h,36h,37h
                                db        38h,39h,41h,42h,43h,44h,45h,46h
        _dial_position          db        50
        _dial_zero_pos_cnt      dw        0
data_s  ends

code_s  segment
assume  ss:stack_s, ds:data_s, cs:code_s

main proc NEAR
                mov        ax,data_s
                mov        ds,ax
                mov        es,ax
                
                mov        ax,3D00h                ;Open file - read
                lea        dx,_input_file
                int        DOS_INTERRUPT
                jc         end_program
                mov        _input_file_handle,ax

        next_instruction:
                call       reset_instruction_memory
                call       read_instruction
                jc         err_program
                cmp        _input_file_char,0
                je         end_program

                call       process_instruction
                jmp        next_instruction

        err_program:
                mov        dl,'E'
                mov        ax,0200h
                int        DOS_INTERRUPT

        end_program:
                call       display_result

                mov        ah,3Eh
                mov        bx,_input_file_handle
                int        DOS_INTERRUPT

                mov        ah,TERM_PROCESS_INT
                mov        al,0
                int        DOS_INTERRUPT
main endp

                ; cf - returns 1 on error
read_instruction proc NEAR
                pushreg
        read_char:
                call       read_char_from_handle
                jc         line_complete
                cmp        _input_file_char,0
                je         line_complete
                mov        al,_input_file_char
                mov        ah,0

                cmp        al,0Ah                        ;Look for LF
                je         line_complete
                
                mov        bx,ax
                and        bl,0F0h
                cmp        bl,30h
                jne        process_direction

                and        al,0Fh                         ; Processing 0-9
                lea        bx,_rot_number_buff
                mov        di,_rot_buff_index
                mov        [bx+di],al
                inc        _rot_buff_index
                jmp        next_char
        process_direction:
                mov        _direction_char,al
        next_char:
                jmp        read_char
        line_complete:
                popreg
                ret
read_instruction endp

                ; cf - returns 1 on error
                ; _input_file_char is 0 when file read is complete
read_char_from_handle proc NEAR
                pushreg
                
                clc
                mov        ax,3F00h                ;Read from file
                mov        bx,_input_file_handle
                mov        cx,1                        ;Read one char
                lea        dx,_input_file_char
                int        DOS_INTERRUPT
                jc         err_read_char_from_hand
                cmp        ax,cx
                je         end_read_char_from_hand        
                mov        _input_file_char,0
                clc
                jmp        end_read_char_from_hand        
                
        err_read_char_from_hand:
                stc
        end_read_char_from_hand:
                popreg
                ret
read_char_from_handle endp

reset_instruction_memory proc NEAR
                push       bx
                push       cx
                push       di

                mov        _direction_char,0
                mov        _rot_buff_index,0
                mov        cx,LENGTH _rot_number_buff
                lea        bx,_rot_number_buff
        clear_num_buff_digit:
                mov        di,cx
                mov        BYTE PTR [bx+di-1],0
                loop       clear_num_buff_digit
                
                pop        di        
                pop        cx
                pop        bx
                ret
reset_instruction_memory endp

process_instruction proc NEAR
                pushreg
                call       number_buffer_to_binary
                mov        ch,0
                mov        cl,_dial_position
                cmp        _direction_char,4Ch                ;'L' direction
                jne        process_right
                sub        cx,ax
                jmp        mod_step
        process_right:
                add        cx,ax
        mod_step:
                mov        ax,cx
                mov        cx,100
                idiv       cl
                or         ah,ah                        ;IDIV two positives can set the
                js         negative_mod                 ;sign flag for reasons??
                mov        _dial_position,ah
                jmp        try_count_zero
        negative_mod:
                mov        _dial_position,100
                add        _dial_position,ah
        try_count_zero:
                cmp        ah,0
                jnz        end_process_instruction
                inc        _dial_zero_pos_cnt
        end_process_instruction:
                popreg
                ret
process_instruction endp

display_result proc NEAR
                pushreg
                mov        cx,4
        next_char_display:
                mov        bx,000Fh
                push       cx
                dec        cx
                shl        cx,1
                shl        cx,1                        ; Mull by 4 for bit count
                shl        bx,cl
                mov        ax,_dial_zero_pos_cnt
                and        ax,bx
                shr        ax,cl
                pop        cx
                lea        bx,_hex_display_tab
                xlat
                mov        dl,al
                mov        ax,0200h
                int        DOS_INTERRUPT
                loop       next_char_display
                popreg
                ret
display_result endp

                ; ax - returns parsed binary number
number_buffer_to_binary proc NEAR
                push       dx
                push       bx
                push       cx
                push       si
                mov        _binary_conv_total,0

                mov        cx,_rot_buff_index
        multiply_ten_pow:
                lea        bx,_ten_pow_tab
                mov        al,cl
                dec        al
                xlat
                mov        dl,al

                lea        bx,_rot_number_buff        
                mov        si,_rot_buff_index
                sub        si,cx
                mov        ah,0
                mov        al,BYTE PTR [bx+si]
                mul        dl
                add        _binary_conv_total,ax
                loop       multiply_ten_pow
                
                mov        ax,_binary_conv_total
                pop        si
                pop        cx
                pop        bx
                pop        dx
                ret
number_buffer_to_binary endp

code_s  ends

end main
