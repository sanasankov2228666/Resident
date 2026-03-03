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
;					              =========== INTERAPT ==========
;
; _______________________________________________________________________________________________________________________________________


; ======================  my_interapt (void) ========================
;                       
; 	entery:    void
; 	exit:      ---                                    
; 	expected:  ---
;	destr:     ax, bx, es
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
		mov ds, ax

		call save_regs

		mov ax, 0b800h
		mov es, ax 

		in al, 60h
		
		cmp al, 7
		jne default_way

		mov ax, [open_close_flag]
		cmp ax, 0
		jne close_wind
			
		mov bx, offset buffer1 

		call save_back
		
		mov bx, FRAME_L
		mov cx, FRAME_H

		call print_frame
		call print_regs

		mov word ptr [open_close_flag], 1

		jmp proces_interapt

		close_wind:
		
		mov bx, offset frame
		call save_back

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



; ============================  save_regs (void) =============================
;
;	entery:    
;	exit:      ---                                
;	expected:  es = VRAM segment
;	destr:     
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
;	expected:  es = VRAM segment
;	destr:     ax, bx, cx, dx, di, si
;	
; ===========================================================================

print_regs:

		; ======= save registers ======

		push ax
		push bx 
		push cx
		push dx
		push di
		push si

		xor si, si

		mov dh, 37
		mov dl, 8

		mov cx, 8

		mov bx, offset str_ax
		
		; ======== loop ========		

		loop_pr:
		
		cmp cx, 0
		je old_loop_pr
		
		call print_reg_line

		inc dl
		dec cx

		add bx, 10
		add si, 2

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



; ==========================  print_reg_line (dl, dh, bx)  =========================
;
;	entery:    dl, dh - y, x, bx buffer adres
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
		call get_offset		

		xor si, si

		; ====== loop ======

		loop_rl:

		cmp cx, 0
		je end_loop_rl
		
		mov ax, [bx + si]
		mov es:[di], ax

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
   		mov es:[di], ax
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
		

		

; ==========================  save_line (bx)  =========================
;
;	entery:    bx - buffer adres
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



; ==========================  print_frame (bx, cx)  =========================
;
;	entery:    bx - lenght
;                  cx - height
;	exit:      ---                                
;	expected:  es = VRAM segment
;	destr:     bx, cx
;	
; ===========================================================================


print_frame:		
			; ===== save registers =====			

			push ax
			push bx
			push cx
			push dx
			push si
			push di

			; ===== find right up corner x y ======

			mov dh, FRAME_X
			mov dl, FRAME_Y
			
			call get_offset				
			
			; ==== top-left corner ====

			mov al, 201
			mov ah, 27
			mov es:[di], ax
			
			; ==== line ====

			call print_x_line	
			
			mov ax, 7099
			mov es:[di], ax
			
			inc dl					; y++
			sub cx, 2

			; ==== begin of the loop ====

			loop_horizontal:
			
			cmp cx, 0
			je end_loop_horizontal
			
			dec cx
			push cx
			call print_in_line
			pop  cx
			inc dl
			
			jmp loop_horizontal

			; ===== end of the loop =====

			end_loop_horizontal:

			call get_offset
		
			mov ax, 7112
			mov es:[di], ax

			call print_x_line	

			mov ax, 7100
			mov es:[di], ax

			; ==== end of func =====
			
			pop di
			pop si
			pop dx
			pop cx
			pop bx
			pop ax
			
			ret


; _______________________________________________________________________________________________________________________________________			


		
; ===========================  print_in_line (void)  =========================
;
;	entry:    void
;	exit:     di - video memory offset
;	expected: es = VRAM segment, bx - leight, dh - x, dl - y
;	destr:    ax, bx, di, cx
;	
; ============================================================================


print_in_line:
			push bx
			push di		

			sub bx, 2	
			
			call get_offset

			; ==== print ( ║ ) begin ====			

			mov cx, 7098
			mov es:[di], cx			; print ( ║ )	blue background, light blue symbol 	

			add di, 2

			loop_line_in_print: 
			
			cmp bx, 0
			je end_loop_line_in_print

			dec bx
			
			mov cx, 4128 
			mov es:[di], cx       ; blue
				
			add di, 2		

			jmp loop_line_in_print

			end_loop_line_in_print:

			; ==== print ( ║ ) end ====

			mov cx, 7098
			mov es:[di], cx			; print ( ║ )	blue background, light blue symbol 	

			pop di
			pop bx
			ret

	
; _______________________________________________________________________________________________________________________________________			

			
		
; ===========================  print_x_line (void)  ===========================
;
;	entry:    void
;	exit:     di - video memory offset
;	expected: es = VRAM segment, bx - leight, dh - x, dl - y
;	destr:    ax, bx, di, cx
;	
; ============================================================================


print_x_line:
			push bx
			push cx		

			sub bx, 2 			
			
			call get_offset
			add di, 2

			loop_line_x_print: 
			
			cmp bx, 0
			je end_loop_line_x_print

			dec bx
			
			mov cx, 5069
			mov es:[di], cx       ; 201 ansi ( ═ ) blue background, light blue symbol 
				
			add di, 2		

			jmp loop_line_x_print

			end_loop_line_x_print:

			pop cx
			pop bx
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
		
		xor ax, ax
		mov es, ax

		mov bx, 36
		
		mov ax, es:[bx]
   		mov [old_ofs_09h], ax
    		mov ax, es:[bx+2]
    		mov [old_seg_09h], ax

    		mov ax, es:[bx]
    		cmp ax, offset my_interapt
    		jne install
    
		mov ax, es:[bx+2]
		mov cx, cs
		cmp ax, cx
		jne install

		mov dx, offset msg_already
   		mov ah, 9
    		int 21h
	
		mov ax, 4C00h
		int 21h 

		install:

		cli
   		mov word ptr es:[bx], offset my_interapt
    		mov word ptr es:[bx+2], cs
   		sti

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
str_bp		 dw 1E42h, 1E42h, 1020h, 1E3Dh, 1020h	; BP =
str_sp		 dw 1E53h, 1E42h, 1020h, 1E3Dh, 1020h	; SP =


old_regs  	 dw 8 dup (0)			; registers before interapt   [ax, bx, cx, dx, di, si, bp, sp]


open_close_flag  dw 0				; openen or closed window

old_ofs_09h 	 dw 0				; old 09h offset
old_seg_09h 	 dw 0				; old 09h segment

msg_already      db 'Already installed$'	; messages for user
msg_installed    db 'Installed$'		; 


frame            db 384 dup (0)		        ; frame copy

buffer1          db 384 dup (0)			; under frame copy


end_label:
end start