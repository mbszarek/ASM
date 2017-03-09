assume cs:kod,ds:dane,ss:stos1
dane segment
  itos db 80 dup ('$')
dane ends

kod segment
start:
  mov ax,seg dane
  mov ds,ax
  xor ax,ax
  mov ax,204
  mov bx,seg itos
  call IntToStr
  mov ah,09h
  mov dx,seg itos
  mov ah,4ch
  int 21h
IntToStr:
  add bx,2
  mov cx,10
convert:
  xor dx,dx
  div cx
  add dl,48d
  mov [bx], dl
  dec bx
  cmp ax,ax
  jnz convert
  ret
kod ends

stos1 segment STACK
  db 200 dup (?)
  top db ?
stos1 ends

end start
