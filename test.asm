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
    
    int 16h
    

    mov ax, 4C00h
    int 21h

end start