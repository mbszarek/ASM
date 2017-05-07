 ; Mateusz Szarek - CRC16 calculator
 ; Computer Science student
 ; Faculty of Computer Science, Electronics and Telecommunications
assume cs:kod,ds:dane,ss:stos1

polycrc EQU 18005h  ;wielomian CRC

dane segment
  args db 127 dup ('$')
  argc dw 0 ;ilosc argumentow
  argv dw 20 dup (?) ;offsety argumentow
  arglen dw 20 dup (0) ;dlugosci argumentow
  flaga dw 1 ;flaga znaku
  proption dw 0  ;modyfikacja
  input1 db 127 dup (?)  ;nazwa pierwszego pliku zakonczona 0 (readonly)
  input1handle dw ?
  input2 db 127 dup (?)  ;nazwa drugiego pliku zakonczona 0 (readonly)
  input2handle dw ?
  output db 127 dup (?)  ;nazwa drugiego pliku zakonczona 0 (writeonly)
  outputhandle dw ?
  bufor db 127 dup('$')
  crc dw 256 dup(0) ;tablica z wartosciami CRC
  err1 db 'No arguments!',0ah,0dh,'$'
  err2 db 'Too low arguments!',0ah,0dh,'$'
  err3 db 'Too much arguments!',0ah,0dh,'$'
  err4 db 'Wrong , only -v is available!',0ah,0dh,'$'
  err5 db 'Cannot open first file!',0ah,0dh,'$'
  err6 db 'Cannot open second file!',0ah,0dh,'$'
dane ends

kod segment
;----------PARSER--------
PARS proc ;procedura parsowania PSP
  push ax
  push bx
  push cx
  push dx
  push si
  push di ;przekazujemy na stos wartosci pod rejestrem aby po zakonczeniu procedury je zdjac
  mov ah,51h  ;upewniamy sie ze w es mamy adres PSP
  int 21h
  mov es,bx
  xor ax,ax
  xor bx,bx
  xor cx,cx
  mov cl,byte ptr es:[80h]  ;przekazujemy do cl ilosc znakow do sparsowania
  cmp cl,01h
  jbe noargs
  dec cl  ;usuwamy pierwsza spacje w 81h
  mov si,82h
  mov di,offset args  ;przekazujemy do rejestru di offset tablicy z argumentami
parsinit:
  push bx
	mov dl,byte ptr es:[si]  ;analiza znaku
	xor bx,bx  ;zerujemy rejestr bx, posluzy nam do okreslenia czy znak jest bialy czy nie
  call whitesign  ;wywolujemy procedure sprawdzajaca czy znak jest bialy
  cmp bx,1  ;porownujemy, 1-znak bialy, 0-nie
  je repl
  pop bx
  xor bx,bx
  mov ds:[flaga],0
  push di
  push si
  push cx
  mov di,offset args  ;offset tablicy z argumentami
  mov cx,ds:[argc]  ;do cx ilosc argumentow
  add di,ax
  add cx,cx ;mnozymy razy dwa
  mov si,offset argv  ;adres tablicy z offsetami argumentow
  add si,cx ;dodajemy do adresu offsetow argumentow ilosc argumentow*2
  add di,ds:[argc]
  mov ds:[si],di
  inc word ptr ds:[argc]  ;inkrementujemy ilosc argumentow
  cmp ds:[argc],3
  ja toomuchargs
  pop cx
  pop si
  pop di
petla:
  cmp cl,0 ;jak zero to nie ma co przenosic
  je koniec ;jak juz nie ma argumentow to wypisujemy
  mov dl,byte ptr es:[si] ;analiza znaku
  inc si  ;przesuwamy wejscie o jeden
  dec cl  ;obnizamy o jeden ilosc znakow
  push bx
  xor bx,bx ;zerujemy rejestr bx, posluzy nam do okreslenia czy znak jest bialy czy nie
  call whitesign  ;wywolujemy procedure sprawdzajaca czy znak jest bialy
  cmp bx,1  ;porownujemy, 1-znak bialy, 0-nie
  je repl ;jesli znak jest bialy to skocz do procedury repl
  pop bx
  mov ds:[di],dl  ;jesli nie jest bialy to po prostu przenies do tablicy
  inc ax  ;ile znakow jest
  inc bx
endpet:
  inc di  ;idziemy o jeden dalej w tablicy argumentow
  jmp petla ;skaczemy dalej do petli
repl:
  pop bx
	cmp ds:[flaga],1
	je replws
replnew:
  mov ds:[flaga],1
  push di
  mov di,offset arglen
  add di,ds:[argc]
  add di,ds:[argc]
  sub di,2
  mov ds:[di],bx
  pop di
  inc di  ;idziemy o jeden dalej w tablicy argumentow
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
whtsgret: ;powrot do procedury
  ret
space:  ;sprawdza czy znak to spacja
  cmp dl,20h
  jne spaceret
  inc bx
spaceret:
  ret
parsnext:
	inc si
	jmp parsinit
tab:  ;sprawdza czy znak to tabulator
  cmp dl,09h
  jne tabret
  inc bx
tabret:
  ret
koniec:
  cmp bx,0
  je last
  push di
  mov di,offset arglen
  add di,ds:[argc]
  add di,ds:[argc]
  sub di,2
  mov ds:[di],bx
  pop di
last:
  pop di
  pop si
  pop dx
  pop cx
  pop bx
  pop ax
  ret
;---sekcja bledow---
toomuchargs:
  push ax
  push dx
  mov ah,09h
  mov dx,offset err3
  int 21h
  pop dx
  pop ax
  jmp endparserror
noargs:
  push ax
  push dx
  mov ah,09h
  mov dx,offset err1
  int 21h
  pop dx
  pop ax
  jmp endparserror
endparserror:
  mov ah,04ch
  int 21h
PARS endp
;---------------------------
;---sprawdzanie argumentow---
CHECKARG proc
    push si
    cmp ds:[argc],3d
    je checkwithmod
    cmp ds:[argc],2d
    jb toolowargs
    pop si
    ret
  checkwithmod: ;jesli 3 argumenty, sprawdzamy czy poprawna opcja
    xor si,si
    mov si,ds:[argv]
    cmp byte ptr ds:[si],"-"
    jne wrongsecondarg
    inc si
    cmp byte ptr ds:[si],"v"
    jne wrongsecondarg
    inc ds:[proption] ;zmieniamy wartosc  na 1
    pop si
    ret
  ;---sekcja bledow---
  wrongsecondarg: ;zly drugi argument
    push ax
    push dx
    mov dx,offset err4
    mov ah,09h
    int 21h
    pop dx
    pop ax
    jmp endcheckerror
  toolowargs: ;zbyt malo argumentow
    push ax
    push dx
    mov ah,09h
    mov dx,offset err2
    int 21h
    pop dx
    pop ax
    jmp endcheckerror
  endcheckerror:  ;koniec programu przez bledy
    pop si
    mov ah,04ch
    int 21h
CHECKARG endp
;---------------------------
;---przepisanie z tablicy argumentow do tablicy nazw plikow---
FILLFILENAME proc
    push ax
    push cx
    push si
    push di
    cmp ds:[proption],1
    je fillwithmod
    mov si,ds:[argv]
    mov di,offset input1
    xor cx,cx
    mov cx,ds:[arglen]
  input1loop:
    xor ax,ax
    mov ah,byte ptr ds:[si]
    mov ds:[di],ah
    inc si
    inc di
    loop input1loop
    xor ax,ax
    mov ds:[di],al
    mov si,ds:[argv+2]
    mov di,offset input2
    xor cx,cx
    mov cx,ds:[arglen+2]
  input2loop:
    xor ax,ax
    mov ah,byte ptr ds:[si]
    mov ds:[di],ah
    inc si
    inc di
    loop input2loop
    xor ax,ax
    mov ds:[di],al
    mov si,ds:[argv+2]
    mov di,offset output
    xor cx,cx
    mov cx,ds:[arglen+2]
  outputloop:
    xor ax,ax
    mov ah,byte ptr ds:[si]
    mov ds:[di],ah
    inc si
    inc di
    loop outputloop
    xor ax,ax
    mov ds:[di],al
    pop di
    pop si
    pop cx
    pop ax
    ret
  fillwithmod:
    mov si,ds:[argv+2]
    mov di,offset input1
    xor cx,cx
    mov cx,ds:[arglen+1]
  input1loopwithmod:
    xor ax,ax
    mov ah,byte ptr ds:[si]
    mov ds:[di],ah
    inc si
    inc di
    loop input1loopwithmod
    xor ax,ax
    mov ds:[di],al
    mov si,ds:[argv+4]
    mov di,offset input2
    xor cx,cx
    mov cx,ds:[arglen+4]
  input2loopwithmod:
    xor ax,ax
    mov ah,byte ptr ds:[si]
    mov ds:[di],ah
    inc si
    inc di
    loop input2loopwithmod
    xor ax,ax
    mov ds:[di],al
    mov si,ds:[argv+4]
    mov di,offset output
    xor cx,cx
    mov cx,ds:[arglen+4]
  outputloopwithmod:
    xor ax,ax
    mov ah,byte ptr ds:[si]
    mov ds:[di],ah
    inc si
    inc di
    loop outputloopwithmod
    xor ax,ax
    mov ds:[di],al
    pop di
    pop si
    pop cx
    pop ax
    ret
FILLFILENAME endp
;--------------------------
;---otwieranie plikow---
OPENFILES proc
    push ax
    push dx
    mov dx,offset input1
    xor ax,ax
    mov ah,3dh
    int 21h
    jc errorfile1
    mov ds:[input1handle],ax
    mov dx,offset input2
    xor ax,ax
    mov al,0
    mov ah,3dh
    int 21h
    jc errorfile2
    mov ds:[input2handle],ax
    pop dx
    pop ax
    ret
  errorfile1:
    push ax
    push dx
    mov dx,offset err5
    mov ah,09h
    int 21h
    pop dx
    pop ax
    jmp fileerrorend
  errorfile2:
    push ax
    push dx
    mov dx,offset err6
    mov ah,09h
    int 21h
    pop dx
    pop ax
    jmp fileerrorend
  fileerrorend:
    pop dx
    pop ax
    mov ah,04ch
    int 21h
OPENFILES endp
;---------------------------
;---wypelnianie tablicy CRC
;FILLCRCTABLE proc
;FILLCRCTABLE endp
;---------------------------
;---zamykanie plikow---
CLOSEFILES proc
    push ax
    push dx
    mov bx,ds:[input1handle]
    mov ah,03eh
    int 21h
    mov bx,ds:[input2handle]
    mov ah,03eh
    int 21h
    pop dx
    pop ax
    ret
CLOSEFILES endp
;---------------------------
;---glowna czesc programu---
  start:
    mov ax,seg dane
    mov ds,ax
    mov ax,seg stos1
    mov ss,ax
    mov ax,offset top
    mov sp,ax
    xor ax,ax
    call PARS
    call CHECKARG
    call FILLFILENAME
    ;call OPENFILES
    ;call CLOSEFILES
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    mov ah,4ch
    int 21h
kod ends
;---koniec programu---

stos1 segment STACK
  dw 200h dup (?)
  top dw ?
stos1 ends

end start
