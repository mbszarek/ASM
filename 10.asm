assume cs:kod,ds:dane,ss:stos1
dane segment
  tekst1 db 'Tojestprogramitu masiezakonczyc',0ah,0dh,'$'
dane ends

kod segment
start:
  mov ax,seg dane
  mov ds,ax
  call wypisz
  mov dx,offset tekst1
  mov ah,9
  int 21h
finish:
  mov ah,4ch
  int 21h
wypisz:
  xor si,si
petla1:
  mov bh,es:[tekst1+si]
  cmp bh,20h
  je finish
  call print
  inc si
  jmp petla1
print:
  mov ah,02h
  int 21h
  ret
SKROC proc
  xor si,si
petla:
  mov ch,ds:[tekst1+si]
  cmp ch,20h
  ja koncz
  inc si
  jmp petla
koncz:
  mov ds:[tekst1+si],'$'
  ret
SKROC endp
kod ends

stos1 segment STACK
  db 200 dup (?)
  top db ?
stos1 ends

end start
