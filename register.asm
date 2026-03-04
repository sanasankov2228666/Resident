.model tiny
.code
org 100h


start: jmp main


; _______________________________________________________________________________________________________________________________________
;						
;					              =========== CONSTANTS ==========
;
; _______________________________________________________________________________________________________________________________________


FRAME_SIZE  equ 384
FRAME_L     equ 16
FRAME_H     equ 12
FRAME_X     equ 34
FRAME_Y     equ 6


; _______________________________________________________________________________________________________________________________________
;						
;					              =========== INTERAPT 08h changed==========
;
; _______________________________________________________________________________________________________________________________________



; ======================  compare_intr (void) ========================
;                       
; 	entery:    void
; 	exit:      ---                                    
; 	expected:  ---
;	destr:     ax, bx, cx, dx, di, si, ds, cs
;
; ===================================================================

compare_intr:

		; ======== save registers ========
	
		push bp
		push si
		push di
		push dx
		push cx
		push bx
		push ax

		push ds
		push es

		mov ax, cs
		mov ds, ax								; put ds = cs

		call save_regs

		mov ax, 0b800h
		mov es, ax								; es = VRAM segment

		mov ax, [open_close_flag]				
		cmp ax, 0								; if closes
		je closed

		; ====== saving regs before interapt =======		

		mov dh, FRAME_X
		mov dl, FRAME_Y

		call get_offset

		xor cx, cx
		xor si, si
		mov bx, offset frame

		; ===== loop =====
	
		begin_loop_ci:

		cmp cx, FRAME_H
		je end_loop_ci
		
		call compare_line

		inc dl
		inc cx

		call get_offset
		
		jmp begin_loop_ci

		; ===== end loop =====

		end_loop_ci:

		cmp [stop_regs_flag], 1
		je closed

		call print_regs						; update regs value

		mov bx, offset frame						
		call buffer_out						; frame out

		; ======== get regs =========

		closed:

		pop es
		pop ds

		pop ax
		pop bx
		pop cx
		pop dx
		pop di
		pop si
		pop bp	

		; ======= jump to old interapt =======

		jmp dword ptr cs:[old_ofs_08h]


; =======================  compare_line (dl, dh) =======================
;                       
; 	entery:    dl, dh - y, x
; 	exit:      ---                                    
; 	expected:  es - VRAM segment, bx - frame adres
;	destr:     ax, cx, di, si
;
; ====================================================================	

compare_line:

		push ax
		push cx
		
		mov cx, FRAME_L

		; ===== loop =====
	
		begin_loop_cl:

		cmp cx, 0
		je end_loop_cl

		mov ax, es:[di]
		cmp ax, [bx + si]
		jne different

		add si, 2
		add di, 2
		dec cx

		jmp begin_loop_cl

		; ====== if different ======

		different:

		push bx

		mov bx, offset buffer1
		mov [bx + si], ax

		pop bx

		mov ax, [bx + si]
		mov es:[di], ax

		add si, 2
		add di, 2
		dec cx

		jmp begin_loop_cl
		
		; ===== end loop =====

		end_loop_cl:

		pop cx
		pop ax

		ret


; _______________________________________________________________________________________________________________________________________
;						
;					              =========== INTERAPT 09h changed==========
;
; _______________________________________________________________________________________________________________________________________


; ======================  my_interapt (void) ========================
;                       
; 	entery:    void
; 	exit:      ---                                    
; 	expected:  ---
;	destr:     ax, bx, cx, dx, di, si, ds, es
;
; ==================================================================

my_interapt:  
		
		; ======== save registers ========
	
		push bp
		push si
		push di
		push dx
		push cx
		push bx
		push ax

		push ds
		push es

		; ====== saving regs before interapt =======		

		mov ax, cs
		mov ds, ax								; put ds = cs

		call save_regs

		mov ax, 0b800h
		mov es, ax 								; es = VRAM segment

		in al, 60h					
		
		cmp al, 7								; if button not ( 6 - open or close window )
		je window_proccesing

		cmp al, 8								; if button not ( 7 - open or close window )
		jne default_way

		xor [stop_regs_flag], 1

		jmp proces_interapt

		window_proccesing:

		; ======= check window flag =======

		mov ax, [open_close_flag]		
		cmp ax, 0								; check if opened window
		jne close_wind
			
		; ======= output window =======

		mov bx, offset buffer1 					; save back in buffer1
		call save_back

		call print_regs

		mov bx, offset frame
		call buffer_out

		mov word ptr [open_close_flag], 1		; put window is opened

		jmp proces_interapt	

		; ======= close window =======

		close_wind:

		mov bx, offset buffer1
		call buffer_out

		mov word ptr [open_close_flag], 0
		
		; ======== proccesing interapt =========

		proces_interapt:

		in  al, 61h
		or  al, 80h
		out 61h, al
		and al, not 80h
		out 61h, al

		mov al, 20h
		out 20h, al

		pop es
		pop ds

		pop ax
		pop bx
		pop cx
		pop dx
		pop di
		pop si
		pop bp	
	
		iret

		; ========= get registers =========
		
		default_way:

		pop es
		pop ds

		pop ax
		pop bx
		pop cx
		pop dx
		pop di
		pop si
		pop bp		

		; ======= go to old 09h ========= 

		jmp dword ptr cs:[old_ofs_09h]


; _________________________________________________________________________________________________________________________________________________



; ============================  save_regs (void) =============================
;
;	entery:    void
;	exit:      ---                                
;	expected:  es = VRAM segment, stack - [ax], [bx], [cx], [dx], [di], [si], [bp], [ip, cs, flags]
;	destr:     bp, bx, cx, si
;	
; ===========================================================================

save_regs:
		push bp
		push bx
		push cx
		push si

		xor si, si
		mov cx, 7

		mov bp, sp
		add bp, 14
	
		mov bx, offset old_regs
	
		; ====== loop =========

		loop_sr:
		
		cmp cx, 0
		je end_loop_sr

		mov ax, [bp]
		mov [bx + si], ax
		
		add si, 2
		add bp, 2		
		
		dec cx

		jmp loop_sr
		
		; ====== end loop =======

		end_loop_sr:

		add bp, 6
		mov [bx + si], bp

		pop si
		pop cx
		pop bx
		pop bp

		ret


; ===========================  print_regs (void)  ===========================
;
;	entery:    void
;	exit:      ---                                
;	expected:  ---
;	destr:     ax, bx, cx, dx, di, si
;	
; ===========================================================================

print_regs:

		; ======= save registers =======

		push ax
		push bx 
		push cx
		push dx
		push di
		push si

		xor si, si

		mov di, offset frame
		add di, 70

		mov cx, 8

		mov bx, offset str_ax
		
		; ======== loop ========		

		loop_pr:
		
		cmp cx, 0
		je old_loop_pr
		
		call print_reg_line

		dec cx

		add bx, 10
		add si, 2
		add di, 32

		jmp loop_pr		

		; ======== end loop =======	

		old_loop_pr:

		pop si
		pop di
		pop dx
		pop cx
		pop bx
		pop ax
	
		ret


; ==========================  print_reg_line (bx, di)  ============================
;
;	entery:    bx, di
;	exit:      ---                               
;	expected:  es = VRAM segment
;	destr:     ax, bx, cx, dx, di, si
;	
; ==================================================================================

print_reg_line:
			
		; ======= save registers ======

		push ax
		push bx 
		push cx
		push dx
		push di
		push si
		push si

		mov cx, 5	
		xor si, si

		; ====== loop ======

		loop_rl:

		cmp cx, 0
		je end_loop_rl
		
		mov ax, [bx + si]
		mov [di], ax

		add di, 2
		add si, 2

		dec cx
		
		jmp loop_rl

		; ======= get registers ======
		
		end_loop_rl:

		pop si
		call print_reg_val
		
		pop si
		pop di
		pop dx
		pop cx
		pop bx
		pop ax
		
		ret



; ==========================  print_reg_val (di, si)  =========================
;
;	entery:    di - vram offset, si - reg coounter
;	exit:      ---                                
;	expected:  es = VRAM segment
;	destr:     ax, bx, cx, dx, di, si
;	
; ==================================================================================

print_reg_val:

		push bx
		push cx

    	mov bx, [old_regs + si] 
    	mov cx, 4               

		loop_hex:
    	rol bx, 4 
    	mov al, bl
   		and al, 0Fh
    
   		cmp al, 10
   		jl is_digit
   		add al, 7 
		is_digit:
    	add al, '0'
    
   		mov ah, 1Eh 
   		mov [di], ax
   		add di, 2
    	loop loop_hex

    	pop cx
   		pop bx

    	ret



; =============================  buffer_out (bx)  ===========================
;
;	entery:    bx - adres buffer
;	exit:      ---                                
;	expected:  es = VRAM segment
;	destr:     ax, bx, cx, dx, di
;	
; ===========================================================================

buffer_out:

		; ======= save registers ======

		push ax
		push bx 
		push cx
		push dx
		push di

		mov cx, FRAME_H

		mov dh, FRAME_X
		mov dl, FRAME_Y

		call get_offset

		; ====== loop buffer out ======

		loop_bo:

		cmp cx, 0
		je end_loop_bo
		
		call buffer_line_out

		inc dl
		dec cx

		call get_offset
		
		jmp loop_bo
	
		; ===== end loop =====

		end_loop_bo:

		; ======= get registers ======
		
		pop di
		pop dx
		pop cx
		pop bx
		pop ax
		
		ret


; ==========================  buffer_line_out (bx)  =========================
;
;	entery:    bx - adres buffer
;	exit:      ---                                
;	expected:  es = VRAM segment
;	destr:     dx, di
;	
; ===========================================================================

buffer_line_out:

		push ax
		push cx
		
		mov cx, FRAME_L

		; ===== loop =====
	
		begin_loop_blo:

		cmp cx, 0
		je end_loop_blo

		mov ax, [bx]
		mov es:[di], ax

		add bx, 2
		add di, 2
		dec cx

		jmp begin_loop_blo
		
		; ===== end loop =====

		end_loop_blo:

		pop cx
		pop ax

		ret
		

; _________________________________________________________________________________________________________________________________________________


; ============================  save_back (void)  ===========================
;
;	entery:    bx - adres buffer
;	exit:      ---                                
;	expected:  es = VRAM segment
;	destr:     ax, bx, cx, dx, di
;	
; ===========================================================================

save_back:	

		; ======= save registers ======

		push ax
		push bx 
		push cx
		push dx
		push di

		xor cx, cx

		mov dh, FRAME_X
		mov dl, FRAME_Y

		call get_offset
		
		; ===== loop =====
	
		begin_loop_sb:

		cmp cx, FRAME_H
		je end_loop_sb
		
		call save_line

		inc dl
		inc cx

		call get_offset
		
		jmp begin_loop_sb

		; ===== end loop =====

		end_loop_sb:


		; ======= get registers ======
		
		pop di
		pop dx
		pop cx
		pop bx
		pop ax
		
		ret
		

; _________________________________________________________________________________________________________________________________________________
	


; ==========================  save_line (bx)  =========================
;
;	entery:    bx - buffer adres dl, dh - y, x
;	exit:      bx - end of line                              
;	expected:  di - adres line begin, es - video ram segment
;	destr:     ax, bx, cx, di
;	
; ===========================================================================

save_line:	
		push ax
		push cx
		
		mov cx, FRAME_L

		; ===== loop =====
	
		begin_loop_sl:

		cmp cx, 0
		je end_loop_sl

		mov ax, es:[di]
		mov [bx], ax

		add bx, 2
		add di, 2
		dec cx

		jmp begin_loop_sl
		
		; ===== end loop =====

		end_loop_sl:

		pop cx
		pop ax

		ret

; _______________________________________________________________________________________________________________________________________
;						
;					         =========== FRAME FUNCS ==========
; _______________________________________________________________________________________________________________________________________


; _________________________________________________________________________________________________________________________________________________



; ===========================  write_frame (void)  ==========================
;
;	entery:    void
;	exit:      ---                                
;	expected:  ---
;	destr:     ax, bx, cx
;	
; ===========================================================================


write_frame:		
			; ===== save registers =====			

			push ax
			push bx
			push cx		
			
			; ==== top-left corner ====

			mov bx, offset frame				; bx - frame buffer adres

			mov al, 201
			mov ah, 27

			mov [bx], ax

			add bx, 2
			
			; ==== line ====

			call write_x_line	
			
			mov ax, 7099
			mov [bx], ax						; right top corner
			add bx, 2
			
			mov cx, FRAME_H
			sub cx, 2							; cx - count in lines

			; ==== begin of the loop ====

			loop_horizontal:
			
			cmp cx, 0
			je end_loop_horizontal
			
			dec cx
			call write_in_line
			
			jmp loop_horizontal

			; ===== end of the loop =====

			end_loop_horizontal:
		
			mov ax, 7112
			mov [bx], ax
			add bx, 2

			call write_x_line	

			mov ax, 7100
			mov [bx], ax

			; ==== end of func =====
			
			pop cx
			pop bx
			pop ax
			
			ret


; _______________________________________________________________________________________________________________________________________			


		
; ===========================  write_in_line (void)  =========================
;
;	entry:    void
;	exit:     bx - current buffer adres
;	expected: ---
;	destr:    ax, bx, cx
;	
; ============================================================================


write_in_line:

			push ax
			push cx

			mov cx, FRAME_L
			sub cx, 2

			; ==== write ( ║ ) begin ====			

			mov ax, 7098
			mov [bx], ax			; write ( ║ )	blue background, light blue symbol 	
			add bx, 2

			loop_line_in_write: 
			
			cmp cx, 0
			je end_loop_line_in_write

			dec cx
			
			mov ax, 4128 
			mov [bx], ax       ; blue
			add bx, 2		

			jmp loop_line_in_write

			end_loop_line_in_write:

			; ==== write ( ║ ) end ====

			mov ax, 7098
			mov [bx], ax			; write ( ║ )	blue background, light blue symbol 	
			add bx, 2

			pop cx
			pop ax

			ret

	
; _______________________________________________________________________________________________________________________________________			

			
		
; ===========================  write_x_line (void)  ===========================
;
;	entry:    void
;	exit:     bx - current buffer adres
;	expected: ---
;	destr:    ax, bx, cx
;	
; ============================================================================


write_x_line:

			push ax
			push cx		

			mov cx, FRAME_L
			sub cx, 2	

			loop_line_x_write: 
			
			cmp cx, 0
			je end_loop_line_x_write

			dec cx
			
			mov ax, 5069
			mov [bx], ax       ; 201 ansi ( ═ ) blue background, light blue symbol 
				
			add bx, 2		

			jmp loop_line_x_write

			end_loop_line_x_write:

			pop cx
			pop ax
			ret


; _______________________________________________________________________________________________________________________________________			

			
		
; ===========================  get_offset  =================================
;
;	entry:    dh - x, dl - y
;	exit:     di - video memory offset
;	destr:    ax, bx
;	
; ==========================================================================

get_offset:
			push ax
			push bx
	
			xor ax, ax
			xor bx, bx			

			mov al, dl
			mov bl, 160
			mul bl					; ax = row * 160
			
			mov bl, dh
			shl bx, 1				; bx = column * 2
			
			add ax, bx
			mov di, ax
			
			pop bx
			pop ax
			ret			
			
			

; _______________________________________________________________________________________________________________________________________
;
;						        =========== MAIN ============
; _______________________________________________________________________________________________________________________________________



; ======================================================================
;                                    main
; ======================================================================

main:
		
		xor ax, ax						; ax = 0
		mov es, ax						; es = 0

		
		; ======= save 09h adres ========

		mov bx, 36						; bx = 36

		mov ax, es:[bx]					; ax = offset 09h
   		mov [old_ofs_09h], ax			; saved offset of 09h
    	mov ax, es:[bx+2]				; ax = segment 09h
    	mov [old_seg_09h], ax			; saved segment 09h


		; ======= save 08h adres ========

		mov bx, 32						; bx = 32

		mov ax, es:[bx]					; ax = offset 08h
   		mov [old_ofs_08h], ax			; saved offset of 08h
    	mov ax, es:[bx+2]				; ax = segment 08h
    	mov [old_seg_08h], ax			; saved segment 08h

		; ======== check if interapt instaled =======

    	mov ax, es:[bx]					
		cmp ax, offset compare_intr	; check if instaled 08h new offset
		jne install

		mov ax, es:[bx+2]
		mov cx, cs
		cmp ax, cx						; check if instaled 08h new segment
		jne install

		mov bx, 36

		mov ax, es:[bx]					
		cmp ax, offset my_interapt		; check if instaled 09h new offset
		jne install
    
		mov ax, es:[bx+2]
		mov cx, cs
		cmp ax, cx						; check if instaled 09h new segment
		jne install

		; ======== already instaled =========

		mov dx, offset msg_already
   		mov ah, 9
    	int 21h
	
		mov ax, 4C00h
		int 21h 

		; ======== instalation =========

		install:					

		cli
   		mov word ptr es:[36], offset my_interapt	; changed interapt adres
    	mov word ptr es:[36+2], cs

   		mov word ptr es:[32], offset compare_intr	; changed interapt adres
    	mov word ptr es:[32+2], cs
   		sti

		; ======== end of instalation =========

		call write_frame							; write frame in buffer

		mov dx, offset msg_installed
   		mov ah, 9
    	int 21h

		mov dx, offset end_label
		shr dx, 4         
		inc dx
		mov ax, 3100h
		int 21h    

; _________________________________________________________________________________________________________________________________________________



; ======================================================================
; 	      		 	    data
; ======================================================================


str_ax		 dw 1E41h, 1E58h, 1020h, 1E3Dh, 1020h	; AX = 
str_bx		 dw 1E42h, 1E58h, 1020h, 1E3Dh, 1020h	; BX =
str_cx		 dw 1E43h, 1E58h, 1020h, 1E3Dh, 1020h	; CX =
str_dx		 dw 1E44h, 1E58h, 1020h, 1E3Dh, 1020h	; DX =
str_di		 dw 1E44h, 1E49h, 1020h, 1E3Dh, 1020h	; DI =
str_si		 dw 1E53h, 1E49h, 1020h, 1E3Dh, 1020h	; SI =
str_bp		 dw 1E42h, 1E50h, 1020h, 1E3Dh, 1020h	; BP =
str_sp		 dw 1E53h, 1E50h, 1020h, 1E3Dh, 1020h	; SP =


old_regs  	 dw 8 dup (0)			; registers before interapt   [ax, bx, cx, dx, di, si, bp, sp]


open_close_flag  dw 0				; openen or closed window
stop_regs_flag   dw 0				; openen or closed window

old_ofs_09h 	 dw 0				; old 09h offset
old_seg_09h 	 dw 0				; old 09h segment

old_ofs_08h 	 dw 0				; old 08h offset
old_seg_08h 	 dw 0				; old 08h segment

msg_already      db 'Already installed$'	; messages for user
msg_installed    db 'SUCCESSFULLY INSTALLED$'		 


frame            db FRAME_SIZE dup (0)		    ; frame copy

buffer1          db FRAME_SIZE dup (0)			; under frame copy


end_label:
end start