assume cs:kod, ss:stos1, ds:dane
dane segment
dane ends

kod segment
start:
    mov ax,seg dane
    mov ds,ax
    xor ax,ax
    mov ax,57
    mov bl,10
    call printnum
    mov ah,4ch
    int 21h
printn:
    add dl,48d
    mov ah,02h
    int 21h
    ret
printnum:
    xor cx,cx
    mov bl,10
    div bl
    push ax
    inc cx
    xor ah,ah
    cmp ax,0
    jne printnum
    mov dl,ah
    call printn
pk:
    pop dx
    call printn
    dec cx
    cmp cx,0
    jne pk
    ret
kod ends

stos1 segment STACK
    db 200 dup (?)
    top1 db ?
stos1 ends

end start
