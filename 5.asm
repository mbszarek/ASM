assume cs:kod,ds:dane,ss:stos1
dane segment
  input db 80 dup ('$')
dane ends

kod segment
start:
  mov ax,seg dane
  mov ds,ax
  push dh
  pop dh
  mov ah,4ch
  int 21h
kod ends

stos1 segment STACK
  db 200 dup (?)
  top db ?
stos1 ends

end start
