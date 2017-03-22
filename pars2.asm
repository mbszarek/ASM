 ;Mateusz Szarek - parser ASM 80x86
assume cs:kod,ds:dane,ss:stos1
dane segment
  args db 100 dup ('$')
  argc dw 0 ;ilosc argumentow
  argv dw 20 dup (?) ;offsety argumentow
  arglen dw 20 dup (0) ;dlugosc argumentow
  key db 16 dup (0)
  flaga dw 1 ;flaga znaku
  err1 db 'Nie podano zadnych argumentow!',0ah,0dh,'$'
  err2 db 'Podano zbyt malo argumentow!',0ah,0dh,'$'
  err3 db 'Podano zbyt duzo argumentow!',0ah,0dh,'$'
  err4 db 'Zbyt dlugi pierwszy argument!',0ah,0dh,'$'
  err5 db 'Zbyt krotki drugi argument!',0ah,0dh,'$'
  err6 db 'Zbyt dlugi drugi argument!',0ah,0dh,'$'
  err7 db 'Niedozwolone wartosci w drugim argumencie!',0ah,0dh,'$'
  carg db 0ah,0dh,'Ilosc argumentow: $'
dane ends

kod segment
;----------PARSER--------
PARS proc
  push ax
  push bx
  push cx
  push dx
  push si
  push di;przekazujemy na stos wartosci pod rejestrem aby po zakonczeniu procedury je zdjac
  xor ax,ax
  xor bx,bx
  xor cx,cx
  mov cl,byte ptr es:[80h];przekazujemy do cl ilosc znakow do sparsowania
  cmp cl,01h
  jbe error1
  dec cl;usuwamy pierwsza spacje w 81h
  mov si,82h
  mov di,offset args;przekazujemy do rejestru di offset tablicy z argumentami
parsinit:
  push bx
	mov dl,byte ptr es:[si];analiza znaku
	xor bx,bx;zerujemy rejestr bx, posluzy nam do okreslenia czy znak jest bialy czy nie
  call whitesign;wywolujemy procedure sprawdzajaca czy znak jest bialy
  cmp bx,1;porownujemy, 1-znak bialy, 0-nie
  je repl
  pop bx
  xor bx,bx
  mov ds:[flaga],0
  push di
  push si
  push cx
  mov di,offset args;offset tablicy z argumentami
  mov cx,ds:[argc];do cx ilosc argumentow
  add di,ax
  ;add di,cx
  add cx,cx;mnozymy razy dwa
  mov si,offset argv;adres tablicy z offsetami argumentow
  add si,cx;dodajemy do adresu offsetow argumentow ilosc argumentow*2
  add di,ds:[argc]
  mov ds:[si],di
  inc word ptr ds:[argc];inkrementujemy ilosc argumentow
  pop cx
  pop si
  pop di
petla:
  cmp cl,0 ;jak zero to nie ma co przenosic
  je koniec;jak juz nie ma argumentow to wypisujemy
  ;je koniec
  mov dl,byte ptr es:[si];analiza znaku
  inc si;przesuwamy wejscie o jeden
  dec cl;obnizamy o jeden ilosc znakow
  push bx
  xor bx,bx;zerujemy rejestr bx, posluzy nam do okreslenia czy znak jest bialy czy nie
  call whitesign;wywolujemy procedure sprawdzajaca czy znak jest bialy
  cmp bx,1;porownujemy, 1-znak bialy, 0-nie
  je repl;jesli znak jest bialy to skocz do procedury repl
  pop bx
  mov ds:[di],dl;jesli nie jest bialy to po prostu przenies do tablicy
  inc ax;ile znakow jest
  inc bx
endpet:
  inc di;idziemy o jeden dalej w tablicy argumentow
  jmp petla;skaczemy dalej do petli
repl:
  pop bx
	cmp ds:[flaga],1
	je replws
replnew:
  ;mov byte ptr ds:[di],0ah;dajemy znak nowej linii
  mov ds:[flaga],1
  push di
  mov di,offset arglen
  add di,ds:[argc]
  sub di,1
  mov ds:[di],bx
  pop di
  inc di;idziemy o jeden dalej w tablicy argumentow
  jmp parsinit
replws:
	inc si
	dec cl
	jmp parsinit
whitesign:
  call space
  cmp bx,1
  je whtsgret
  call tab
whtsgret:;powrot do procedury
  ret
space:;sprawdza czy znak to spacja
  cmp dl,20h
  jne spaceret
  inc bx
spaceret:
  ret
parsnext:
	inc si
	jmp parsinit
tab:;sprawdza czy znak to tabulator
  cmp dl,09h
  jne tabret
  inc bx
tabret:
  ret
error1:
  mov dx,offset err1;wypisanie bledu na ekran
  mov ah,09h
  int 21h
koniec:
  cmp bx,0
  je last
  push di
  mov di,offset arglen
  add di,ds:[argc]
  sub di,1
  mov ds:[di],bx
  pop di
last:
  pop di
  pop si
  pop dx
  pop cx
  pop bx
  pop ax
  jmp wypisuj
PARS endp
WYPISZ proc
  push ax
  push bx
  push cx
  push dx
  push si
  mov cx,ds:[argc]
  mov si,offset argv
printing:
  mov dx,ds:[si]
  mov ah,09h
  int 21h
  mov dl,0ah
  mov ah,02h
  int 21h
  add si,2
  loop printing
  pop si
  pop dx
  pop cx
  pop bx
  pop ax
  ret
WYPISZ endp
CHECKARG proc
  push ax
  push bx
  push cx
  push dx
  cmp ds:[argc],2
  jb error1
  cmp ds:[argc],2
  ja error2
  cmp byte ptr ds:[arglen],01h
  jne error3
  cmp byte ptr ds:[arglen+1],32
  jb error4
  cmp byte ptr ds:[arglen+1],32
  ja error5

  jmp checkret
error1:;zbyt malo argumentow
  push ax
  push dx
  mov ah,09h
  mov dx,offset err2
  int 21h
  pop dx
  pop ax
  jmp checkret
error2:;zbyt duzo argumentow
  push ax
  push dx
  mov ah,09h
  mov dx,offset err3
  int 21h
  pop dx
  pop ax
  jmp checkret
error3:;zbyt dlugi pierwszy argument
  push ax
  push dx
  mov ah,09h
  mov dx,offset err4
  int 21h
  pop dx
  pop ax
  jmp checkret
error4:;zbyt krotki drugi argument
  push ax
  push dx
  mov ah,09h
  mov dx,offset err5
  int 21h
  pop dx
  pop ax
  jmp checkret
error5:;zbyt dlugi drugi argument
  push ax
  push dx
  mov ah,09h
  mov dx,offset err6
  int 21h
  pop dx
  pop ax
  jmp checkret
checkkey:
  push ax
  push bx
  push cx
  push dx
  push di
  push si
  mov si,offset key
  dec si
  mov di,ds:[argv+1]
  mov bx,32
chloop:
  inc si
  mov cx,1
chloop2:
  mov dh,ds:[di]
  jmp checksmall
bpoint:
  push ax
  push bx
  xor ax,ax
  mov al,ds:[si]
  mov bl,16
  mul bl
  add al,dh
  mov ds:[si],al
  pop bx
  pop ax
  dec bx
  inc di
  loop chloop2
  cmp bx,0
  jne chloop
  pop si
  pop di
  pop dx
  pop cx
  pop bx
  pop ax
  ret
checksmall:
  cmp dh,061h
  jb checkbig
  cmp dh,066h
  ja error6
  sub dh,87
  jmp bpoint
checkbig:
  cmp dh,041h
  jb checknum
  cmp dh,046h
  ja error6
  sub dh,55
  jmp bpoint
checknum:
  cmp dh,030h
  jb error6
  cmp dh,039h
  ja error6
  sub dh,030h
  jmp bpoint
error6:
  push ax
  push dx
  mov ah,09h
  mov dx,offset err7
  int 21h
  pop dx
  pop ax
  jmp checkret
checkret:
  pop dx
  pop cx
  pop bx
  pop ax
  ret
CHECKARG endp
start:
  mov ax,seg dane
  mov ds,ax
  mov ax,seg stos1
  mov ss,ax
  mov ax,offset top
  mov sp,ax
  xor ax,ax
  call PARS
wypisuj:
  pop di
  pop si
  pop dx
  pop cx
  pop bx
  pop ax
  ;mov dx,ds:[arglen]
  ;add dx,30h
  ;mov ah,02h
  ;int 21h
  mov dl,ds:[key+1]
  add dl,30h
  mov ah,02h
  int 21h
  call WYPISZ
  call CHECKARG
  mov dx,offset carg
  mov ah,09h
  int 21h
  mov dx,ds:[argc]
  add dx,30h
  mov ah,02h
  int 21h
fin:
  mov ah,4ch
  int 21h
kod ends

stos1 segment STACK
  dw 200 dup (?)
  top dw ?
stos1 ends

end start
