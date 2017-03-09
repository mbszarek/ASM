assume cs:kod,ds:dane,ss:stos1
dane segment
  tekst1 db 'Hello world!$'
dane ends

kod segment
start:
  mov ax,seg tekst1
  mov ds,ax
  xor ax,ax
  ;mov ax,es:[080h]
  mov ax,es:[080h]
  xor ah,ah
  call PRINTN
  ;mov bx,offset tekst1
  ;call COUNT
  ;mov ax,14 ;ax to dzielna
  ;mov bl,10 ;bl to dzielnik
  ;call PRINTN
  finish:
    mov ah,4ch
    int 21h
COUNT proc
  xor cx,cx
  licz:
    cmp byte ptr ds:[bx],24h
    je print
    inc cx;zlicza znaki
    inc bx;wskaznik na tekst
    jmp licz;petla
  print:
    mov ax,cx
    call PRINTN
COUNT endp
PRINTN proc
  push ax
  push bx
  push cx
  push dx
  mov bl,10
  xor cx,cx ;zerujemy rejestr cx - bedzie sluzyl jako ilosc cyfr
  cyfr:
    div bl ;dzielimy
    push ax ;zapisujemy ax na stos
    inc cx ;inkrementacja cx
    xor ah,ah ;zerujemy modulo
    cmp al,0 ;porownujemy do 0, jak nie jest rowne to lecimy
    jne cyfr
  wypisz:
    pop dx ;sciagamy ze stosu kolejne cyfry
    mov dl,dh ;przenosimy do rejestru dl
    add dl,48d ;zamieniamy na kod ASCII
    call PUTC ;do konsoli
    dec cx ;licznik jeb w dol
    cmp cx,0 ;porownanie do 0
    jne wypisz
  jmp finish
PRINTN endp
PUTC proc
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
PUTC endp
kod ends

stos1 segment STACK
  dw 200 dup (?)
  top dw ?
stos1 ends

end start
