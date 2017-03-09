assume cs:kod, ds:dane, ss:stos1
dane segment
  req db 'Podaj liczbe: $'
  bad_msg db 'Nie podales liczby!',0ah,0dh,'$'
  newl db 0ah,0dh,'$'
  good_msg db 'Podales cyfre! - $'
dane ends

kod segment
start:
  mov ax,seg dane
  mov ds,ax
  mov dx,offset req
  call puts
  call getc
  mov dx,offset newl
  call puts
  cmp al,'0'
  jb invalid
  cmp al,'9'
  ja invalid
  mov dx,offset good_msg
  call puts
  mov dl,al
  call putc
  mov dx,offset newl
  call puts
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
puts:
  push ax
  push bx
  push cx
  push dx
  mov ah,09h
  int 21h
  pop dx
  pop cx
  pop bx
  pop ax
  ret
getc:
  push bx
  push cx
  push dx
  mov ah,01h
  int 21h
  pop dx
  pop cx
  pop bx
  ret
invalid:
  push ax
  push bx
  push cx
  push dx
  mov dx,offset bad_msg
  call puts
  mov dx,offset newl
  call puts
  pop dx
  pop cx
  pop bx
  pop ax
  jmp finish
kod ends

stos1 segment STACK
  db 200 dup (?)
  top db ?
stos1 ends

end start
