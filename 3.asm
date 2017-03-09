assume cs:kod,ds:dane,ss:stos1
dane segment
dane ends

kod segment
start:
  mov ax,seg dane
  mov ds,ax
  mov dl,'*'
  xor dh,dh
  call putsxty
finish:
  mov ah,4ch
  int 21h
putc:
  push ax
  push bx
  push cx
  push dx
  mov ah,02h
  int 21h
  pop dx
  pop cx
  pop bx
  pop ax
  ret
putsxty:
  mov cx,1d
disp:
  cmp cx,60d
  jnle finish
  call putc
  inc cx
  jmp disp
kod ends

stos1 segment STACK
  db 200 dup (?)
  top db ?
stos1 ends

end start
