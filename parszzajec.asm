 ;Mateusz Szarek - parser ASM 80x86
assume cs:kod,ds:dane,ss:stos1
dane segment
  args db 100 dup ('$')
  argc dw 0 ;ilosc argumentow
  argv dw 20 dup (?) ;offsety argumentow
  flaga dw 1 ;flaga znaku
  err1 db 'Nie podano zadnych argumentow!',0ah,0dh,'$'
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
  je wypisz;jak juz nie ma argumentow to wypisujemy
  ;je koniec
  mov dl,byte ptr es:[si];analiza znaku
  inc si;przesuwamy wejscie o jeden
  dec cl;obnizamy o jeden ilosc znakow
  xor bx,bx;zerujemy rejestr bx, posluzy nam do okreslenia czy znak jest bialy czy nie
  call whitesign;wywolujemy procedure sprawdzajaca czy znak jest bialy
  cmp bx,1;porownujemy, 1-znak bialy, 0-nie
  je repl;jesli znak jest bialy to skocz do procedury repl
  mov ds:[di],dl;jesli nie jest bialy to po prostu przenies do tablicy
  inc ax;ile znakow jest
endpet:
  inc di;idziemy o jeden dalej w tablicy argumentow
  jmp petla;skaczemy dalej do petli
repl:
	cmp ds:[flaga],1
	je replws
replnew:
  ;mov byte ptr ds:[di],0ah;dajemy znak nowej linii
  mov ds:[flaga],1
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
  pop di
  pop si
  pop dx
  pop cx
  pop bx
  pop ax
  jmp fin
PARS endp
WYPISZ2 proc
  push ax
  push bx
  push cx
  push dx
  push si
  mov cx,ds:[argc]
  mov si,offset argv
wypisuj:
  mov dx,ds:[si]
  mov ah,09h
  int 21h
  mov dl,0ah
  mov ah,02h
  int 21h
  add si,2
  loop wypisuj
  pop si
  pop dx
  pop cx
  pop bx
  pop ax
  ret
WYPISZ2 endp
start:
  mov ax,seg dane
  mov ds,ax
  mov ax,seg stos1
  mov ss,ax
  mov ax,offset top
  mov sp,ax
  xor ax,ax
  call PARS
wypisz:
  pop di
  pop si
  pop dx
  pop cx
  pop bx
  pop ax
  call WYPISZ2
  mov dx,offset carg
  mov ah,09h
  int 21h
  mov dx,ds:[argc]
  add dx,48d
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
