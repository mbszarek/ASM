 ;Mateusz Szarek - parser ASM 80x86
assume cs:kod,ds:dane,ss:stos1
dane segment
  args db 100 dup ('$')
  argc dw 0 ;ilosc argumentow
  argv dw 20 dup (?) ;offsety argumentow
  arglen dw 20 dup (0) ;dlugosc argumentow
  key db 16 dup (0)
  fmod db 0
  flaga dw 1 ;flaga znaku
  chess db 153 dup (0)
  x db 8
  y db 4
  startpos db 76
  err1 db 'Nie podano zadnych argumentow!',0ah,0dh,'$'
  err2 db 'Podano zbyt malo argumentow!',0ah,0dh,'$'
  err3 db 'Podano zbyt duzo argumentow!',0ah,0dh,'$'
  err4 db 'Zbyt dlugi pierwszy argument!',0ah,0dh,'$'
  err5 db 'Zbyt krotki drugi argument!',0ah,0dh,'$'
  err6 db 'Zbyt dlugi drugi argument!',0ah,0dh,'$'
  err7 db 'Niedozwolone wartosci w pierwszym argumencie!',0ah,0dh,'$'
  err8 db 'Niedozwolone wartosci w drugim argumencie!',0ah,0dh,'$'
  carg db 0ah,0dh,'Ilosc argumentow: $'
  chars db ' ','.','o','+','=','*','B','O','X','@','%','&','#','/','^'
  topframe db 201,205,205,205,'[M. SZAREK]',205,205,205,187,0ah,0dh,'$'
  botframe db 200,205,205,205,205,'[SSH-ART]',205,205,205,205,188,'$'
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
  mov ah,4ch
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

  jmp checkkey;skaczemy do sprawdzania poprawnosci argumentow
error1:;zbyt malo argumentow
  push ax
  push dx
  mov ah,09h
  mov dx,offset err2
  int 21h
  pop dx
  pop ax
  mov ah,4ch
  int 21h
error2:;zbyt duzo argumentow
  push ax
  push dx
  mov ah,09h
  mov dx,offset err3
  int 21h
  pop dx
  pop ax
  mov ah,4ch
  int 21h
error3:;zbyt dlugi pierwszy argument
  push ax
  push dx
  mov ah,09h
  mov dx,offset err4
  int 21h
  pop dx
  pop ax
  mov ah,4ch
  int 21h
error4:;zbyt krotki drugi argument
  push ax
  push dx
  mov ah,09h
  mov dx,offset err5
  int 21h
  pop dx
  pop ax
  mov ah,4ch
  int 21h
error5:;zbyt dlugi drugi argument
  push ax
  push dx
  mov ah,09h
  mov dx,offset err6
  int 21h
  pop dx
  pop ax
  mov ah,4ch
  int 21h
checkkey:
  push ax
  push bx
  push cx
  push dx
  push di
  push si
  mov di,ds:[argv]
  mov al,ds:[di]
  cmp al,48
  jb error6
  cmp al,49
  ja error6
  sub al,48
  mov ds:[fmod],al
  mov si,offset key
  dec si
  mov di,ds:[argv+2];do rejestru di offset tablicy z argumentami z PSP
  mov bx,32
chloop:
  inc si
  mov cx,2
chloop2:
  mov dh,byte ptr ds:[di]
  jmp checksmall
bpoint:
  push ax
  push bx
  xor ax,ax
  mov al,ds:[si];przenosimy do al liczbe z tablicy
  push cx
  mov cl,04h
  shl al,cl;przesuniecie bitowe o 4 w lewo
  pop cx
  add al,dh
  push ax
  push dx
  ;mov dl,al
  ;mov ah,02h
  ;int 21h
  ;mov dl,0ah
  ;mov ah,02h
  ;int 21h
  pop dx
  pop ax
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
  jmp checkret
checksmall:
  cmp dh,97
  jb checkbig
  cmp dh,102
  ja error7
  sub dh,87
  jmp bpoint
checkbig:
  cmp dh,65
  jb checknum
  cmp dh,70
  ja error7
  sub dh,55
  jmp bpoint
checknum:
  cmp dh,48
  jb error7
  cmp dh,57
  ja error7
  sub dh,48
  jmp bpoint
error6:
  push ax
  push dx
  mov ah,09h
  mov dx,offset err7
  int 21h
  pop dx
  pop ax
  pop si
  pop di
  pop dx
  pop cx
  pop bx
  pop ax
  mov ah,4ch
  int 21h
error7:
  push ax
  push dx
  mov ah,09h
  mov dx,offset err8
  int 21h
  pop dx
  pop ax
  pop si
  pop di
  pop dx
  pop cx
  pop bx
  pop ax
  mov ah,4ch
  int 21h
checkret:
  pop dx
  pop cx
  pop bx
  pop ax
  ret
CHECKARG endp
CHECKMOD proc
  cmp ds:[fmod],1
  je changemod
modret:
  ret
changemod:
  push ax
  push cx
  xor cx,cx
  mov cx,16
  mov di,offset key
modloop:
  xor ax,ax
  mov al,ds:[di]
  cmp al,127
  ja chng
  push cx
  xor cx,cx
  mov cl,01h
  shl ax,cl
  pop cx
loopend:
  mov ds:[di],al
  inc di
  loop modloop
  pop cx
  pop ax
  jmp modret
chng:
  push cx
  xor cx,cx
  mov cl,01h
  shl al,cl
  add al,1
  pop cx
  jmp loopend
CHECKMOD endp
WALK proc
  push di
  push cx
  mov di,offset key
  mov cx,16
walkloop:
  xor ax,ax
  xor bx,bx
  mov al,ds:[di]
walkloopr:
  mov bl,4
  div bl
  cmp ah,0
  je mvul
  cmp ah,1
  je mvur
  cmp ah,2
  je mvdl
  cmp ah,3
  je mvdr
walkbpoint:
  push ax
  push bx
  push cx
  push dx
  push si
  xor ax,ax
  xor bx,bx
  xor cx,cx
  mov al,ds:[y]
  mov bl,17
  mul bl
  add al,ds:[x]
  mov si,offset chess
  xor ah,ah
  add si,ax
  xor ax,ax
  mov al,ds:[si]
  inc al
  mov ds:[si],al
  pop si
  pop dx
  pop cx
  pop bx
  pop ax
  xor ah,ah
  cmp al,0
  jne walkloopr
  inc di
  loop walkloop
  pop cx
  pop di
  ret
mvul:;gora lewo
  cmp ds:[y],0
  je mvul1
  dec ds:[y]
mvul1:
  cmp ds:[x],0
  je walkbpoint
  dec ds:[x]
  jmp walkbpoint
mvur:;gora prawo
  cmp ds:[y],0
  je mvur1
  dec ds:[y]
mvur1:
  cmp ds:[x],16
  je walkbpoint
  inc ds:[x]
  jmp walkbpoint
mvdl:;dol lewo
  cmp ds:[y],8
  je mvdl1
  inc ds:[y]
mvdl1:
  cmp ds:[x],0
  je walkbpoint
  dec ds:[x]
  jmp walkbpoint
mvdr:;dol prawo
  cmp ds:[y],8
  je mvdr1
  inc ds:[y]
mvdr1:
  cmp ds:[x],16
  je walkbpoint
  inc ds:[x]
  jmp walkbpoint
WALK endp
REPLBOARD proc
  push ax
  push bx
  push cx
  push dx
  push si
  push di
  xor cx,cx
  mov cx,153
  mov si,offset chess
boardloop:
  mov di,offset chars
  xor ax,ax
  mov al,ds:[si]
  cmp al,14
  ja toobig
boardloop2:
  xor bx,bx
  add di,ax
  mov bl,ds:[di]
  mov ds:[si],bl
  inc si
  loop boardloop
  push ax
  push bx
  push si
  xor ax,ax
  xor bx,bx
  mov al,ds:[y]
  mov bl,17
  mul bl
  add al,ds:[x]
  mov si,offset chess
  add si,ax
  mov al,'E'
  mov ds:[si],al
  mov al,ds:[startpos]
  mov si,offset chess
  add si,ax
  mov al,'S'
  mov ds:[si],al
  pop si
  pop bx
  pop ax
  pop di
  pop si
  pop dx
  pop cx
  pop bx
  pop ax
  ret
toobig:
  mov al,14
  jmp boardloop2
REPLBOARD endp
PRINTING proc
  push ax
  push bx
  push cx
  push dx
  push si
  push ax
  push dx
  mov dx,offset topframe
  mov ah,09h
  int 21h
  pop dx
  pop ax
  mov si,offset chess
  xor cx,cx
  xor bx,bx
  mov bx,9
linia:
  xor cx,cx
  mov cx,17
  push ax
  push dx
  mov ah,02h
  mov dl,186
  int 21h
  pop dx
  pop ax
druk:
  mov dl,ds:[si]
  mov ah,02h
  int 21h
  inc si
  loop druk
  push ax
  push dx
  mov dl,186
  mov ah,02h
  int 21h
  mov dl,0ah
  mov ah,02h
  int 21h
  mov dl,0dh
  mov ah,02h
  int 21h
  pop dx
  pop ax
  dec bx
  cmp bx,0
  ja linia
  push ax
  push dx
  mov dx,offset botframe
  mov ah,09h
  int 21h
  pop dx
  pop ax
  pop si
  pop dx
  pop cx
  pop bx
  pop ax
  ret
PRINTING endp
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
  call CHECKARG
  call CHECKMOD
  call WALK
  call REPLBOARD
  CALL PRINTING
fin:
  mov ah,4ch
  int 21h
kod ends

stos1 segment STACK
  dw 200 dup (?)
  top dw ?
stos1 ends

end start
