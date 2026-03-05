.model tiny
.code
org 100h

start:

    mov ax, 0011h
    mov bx, 2222h
    mov cx, 3333h
    mov dx, 4444h
    mov si, 5555h
    mov di, 6666h
    mov bp, 7777h

    int 16h
    
    mov ax, 00FFh
    mov bx, 0EEEEh
    mov cx, 0DDDDh
    mov dx, 0CCCCh
    mov si, 0BBBBh
    mov di, 0AAAAh
    mov bp, 9999h
    
    jmp check_button

    wait_escape:

    in  al, 61h
    or  al, 80h
    out 61h, al
    and al, not 80h
    out 61h, al

    mov al, 20h
    out 20h, al

    check_button:

    in al, 60h
    cmp al, 1

    jne wait_escape

    mov ax, 4C00h
    int 21h

end start