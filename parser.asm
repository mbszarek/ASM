assume cs:kod,ds:dane,ss:stos1
dane segment
  args db 100 dup ('$')
  argc db 1 ;ilosc argumentow
  argv db 20 dup (?) ;offsety argumentow
  err1 db 'Niepoprawna ilosc argumentow!',0ah,0dh,'$'
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
  push di ;przekazujemy na stos wartosci pod rejestrem aby po zakonczeniu procedury je zdjac
  mov bl,byte ptr es:[80h]
  cmp bl,01h
  jb error1
  xor cx,cx
  mov cl,byte ptr es:[80h];przekazujemy do cl ilosc znakow do sparsowania
  dec cl;usuwamy pierwsza spacje w 81h
  mov si,82h
  mov di,offset args;przekazujemy do rejestru di offset tablicy z argumentami
petla:
  cmp cl,0
  je wypisz;jak juz nie ma argumentow to wypisujemy
  mov dl,byte ptr es:[si];analiza znaku
  inc si;przesuwamy wejscie o jeden
  dec cl;obnizamy o jeden ilosc znakow
  xor bx,bx;zerujemy rejestr bx, posluzy nam do okreslenia czy znak jest bialy czy nie
  call whitesign;wywolujemy procedure sprawdzajaca czy znak jest bialy
  cmp bx,1;porownujemy, 1-znak bialy, 0-nie
  je repl;jesli znak jest bialy to skocz do procedury repl
  mov ds:[di],dl;jesli nie jest bialy to po prostu przenies do tablicy
endpet:
  inc di;idziemy o jeden dalej w tablicy argumentow
  jmp petla;skaczemy dalej do petli
repl:
  mov byte ptr ds:[di],0ah;dajemy znak nowej linii
  inc byte ptr ds:[argc]
  jmp endpet;dalej do petli
whitesign:
  call space
  cmp bx,1
  je whtsgnext
  call tab
whtsgnext:;powrot do procedury
  ret
space:;sprawdza czy znak to spacja
  cmp dl,20h
  jne spaceret
  inc bx
spaceret:
  ret
tab:;sprawdza czy znak to tabulator
  cmp dl,09h
  jne tabret
  inc bx
tabret:
  ret
error1:
  push ax
  push dx
  mov dx,offset err1
  mov ah,09h
  int 21h
  pop dx
  pop ax
  jmp fin
PARS endp
;-------------------MAIN-------------------
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
  mov dx,offset args
  mov ah,09h
  int 21h
  mov dx,offset carg
  mov ah,09h
  int 21h
  mov dl,ds:[argc]
  add dl,48d
  mov ah,02h
  int 21h
fin:
  mov ah,4ch
  int 21h
kod ends
;-----------------KONIEC---------------

stos1 segment STACK
  db 200 dup (?)
  top db ?
stos1 ends

end start
