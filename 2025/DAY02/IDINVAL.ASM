title   Advent of Code - Day 2
        ; Solution to part 1

;Imports
include ..\stdutil.mac
include ..\stdutil.con

;Constants
RANGE_BUFF_LEN		equ	15

stack_s segment para STACK
        db      200     dup('S')
stack_s ends

data_s  segment
        _input_file             db      'B:\DAY02\SAMPLE02.DAT',0
        ;_input_file            db      'B:\DAY02\INPUT02.DAT',0
        _input_file_handle      dw      0
        _input_file_char        db      0
        _hex_display_tab        db      30h,31h,32h,33h,34h,35h,36h,37h
                                db      38h,39h,41h,42h,43h,44h,45h,46h

	_lower_bound_buff	db	RANGE_BUFF_LEN dup(0)
	_lower_buff_index	db	0
	_upper_bound_buff	db	RANGE_BUFF_LEN dup(0)
	_upper_buff_index	db	0
	
	_range_invalid_id_cnt   dq	0
	_total_invalid_id_cnt   dq	0
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

		call 	parse_next_range
                ;; TODO here

                jmp        end_program
        err_program:
                mov        dl,'E'
                mov        ax,0200h
                int        DOS_INTERRUPT

        end_program:
                call       display_word_result

                mov        ah,3Eh                  ;Close file handle
                mov        bx,_input_file_handle
                int        DOS_INTERRUPT

                mov        ah,TERM_PROCESS_INT
                mov        al,0
                int        DOS_INTERRUPT
main endp

parse_next_range proc NEAR
		pushreg
		call 	zero_range_buffers
	read_next_range_char:
		call    read_char_from_handle
		jc	err_parse_next_range
		cmp	_input_file_char,0
		jz	end_parse_next_range
		
		mov	di,0			; Using DI as upper/lower flag
		mov	ax,_input_file_char
		cmp	ax,02Ch			; Check comma sep
		
		and	ax,0F0h
		cmp	ax,030h
	append_lower_range:
	append_upper_range:
		
		jmp	end_parse_next_range
	err_parse_next_range:
		stc
	end_parse_next_range:
		popreg
		ret
parse_next_range endp

                ; cf - returns 1 on error
                ; _input_file_char is 0 when file read is complete
read_char_from_handle proc NEAR
                pushreg
                clc
                mov        ax,3F00h                ;Read from file
                mov        bx,_input_file_handle
                mov        cx,1                    ;Read one char
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

zero_range_buffers proc NEAR
		pushreg

		mov	di,0
		lea	ax,_lower_bound_buff
		mov	es,ax
		mov	cx,LENGTH _lower_bound_buff
		call	zero_memory
		mov	_lower_buff_index,0

		lea	ax,_upper_bound_buff
		mov	es,ax
		mov	cx,LENGTH _upper_bound_buff
		call	zero_memory
		mov	_upper_buff_index,0

		popreg
		ret
zero_range_buffers endp

		; es - segment pointer to target memory location
		; di - offset from segment pointer to target memory location
		; cx - byte quantity to replace with zero
zero_memory proc NEAR
		pushreg
		cld
		mov	al,0
		rep	stosb
		popreg
		ret
zero_memory endp

display_word_result proc NEAR
                pushreg
                mov        cx,4
        next_char_display:
                mov        bx,000Fh
                push       cx
                dec        cx
                shl        cx,1
                shl        cx,1                    ; Mull by 4 for bit count
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
display_word_result endp

code_s  ends

end main
