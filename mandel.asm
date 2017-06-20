 ; Mateusz Szarek - CRC16 calculator
 ; Computer Science student
 ; Faculty of Computer Science, Electronics and Telecommunications
assume cs:kod,ds:dane,ss:stos1

dane segment
  args db 127 dup ('$')
  argc dw 0 ;ilosc argumentow
  argv dw 20 dup (?) ;offsety argumentow
  arglen dw 20 dup (0) ;dlugosci argumentow
  flaga dw 1 ;flaga znaku
  ;rozdzielczosc ekranu
  horizontal dw 320
  vertical dw 200
  ;do zamiany na floata
  calkowita dw ?  ;"lewa" czesc floata
  ulamek dw ? ;czesc ulamkowa floata
  ulameklen dw ?  ;ilosc cyfr czesci ulamkowej
  dividing dw 10  ;do dzielenia
  sign db 0 ;czy minus
  ;zmienne fpu
  xmin dq -2.0
  xmax dq 1.0
  ymin dq -1.0
  ymax dq 1.0
  float dq 1.0  ;w celu konwersji
  p dq ?
  q dq ?
  pixelcol db ?  ;czarny czy bialy
  condition dq 4.0  ;warunek wyjscia z petli
  tofpu dw ?  ;w celu przenoszenia z cpu do fpu
  ;nie mozna zrobic tego bezposrednio
  err1 db "No arguments.",0ah,0dh,"$"
  error1 db "Too few arguments.",0ah,0dh,"$"
  error2 db "Too much arguments.",0ah,0dh,"$"
  error3 db "Wrong format of arguments.",0ah,0dh,"$"
  debug db "XD",0ah,0dh,"$"
dane ends

kod segment
.386
.387
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
    cmp ds:[argc],4
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
    cmp ds:[argc],4
    jb toolowargs
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
;---sekcja bledow---
  toolowargs:
    push ax
    push dx
    mov ah,09h
    mov dx,offset error1
    int 21h
    pop dx
    pop ax
    jmp endparserror
  toomuchargs:
    push ax
    push dx
    mov ah,09h
    mov dx,offset error2
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
;---wczytanie czesci floatow do pamieci---
VARLOAD proc
    pusha
    mov ax,bx
    mov bx,2d
    mul bx
    mov si,ds:[argv+ax]
    mov cx,ds:[arglen+ax]
    mov ds:[sign],0
    xor ax,ax
    xor bx,bx
    xor dx,dx
    cmp byte ptr ds:[si],'.'
    je wrongformat
    cmp byte ptr ds:[si],'-'
    je changesign
  intpartloop:
    cmp byte ptr ds:[si],'.'
    je floatpart
    cmp byte ptr ds:[si],'9'
    ja wrongformat
    cmp byte ptr ds:[si],'0'
    jb wrongformat
    xor dx,dx
    mov dl,byte ptr ds:[si]
    sub dl,30h
    mov bx,10d
    push dx
    mul bx
    pop dx
    add ax,dx
    inc si
    loop intpartloop
  floatpart:
    mov word ptr ds:[calkowita],ax
    cmp cx,1d
    jbe wrongformat
    inc si
    dec cx
    mov ds:[ulameklen],0d
    xor ax,ax
  floatpartloop:
    cmp byte ptr ds:[si],'9'
    ja wrongformat
    cmp byte ptr ds:[si],'0'
    jb wrongformat
    xor dx,dx
    mov dl,byte ptr ds:[si]
    sub dl,30h
    mov bx,10d
    push dx
    mul bx
    pop dx
    add ax,dx
    inc ds:[ulameklen]
    inc si
    loop floatpartloop
    mov ds:[ulamek],ax
    popa
    ret
  changesign:
    mov ds:[sign],1
    inc si
    dec cx
    jmp intpartloop
  wrongformat:
    mov ah,09h
    mov dx,offset error3
    int 21h
    popa
    mov ah,04ch
    int 21h
VARLOAD endp
;----------------------------
;---obliczanie zmiennych float---
TOFLOAT proc
    pusha
    mov bx,0d
    call VARLOAD
    fild [calkowita]  ;st(2) - calkowita czesc liczby
    fild [dividing]  ;st(1) - podzielnik - 10
    fild [ulamek] ;st(0) - czesc ulamkowa
    mov cx,ds:[ulameklen]
  floatloop1:
    fdiv st(0),st(1)
    loop floatloop1
    cmp ds:[sign],1
    jne zapiszxmin
    fchs
  zapiszxmin:
    fstp qword ptr [xmin]
    fsubp st(0),st(0) ;zerujemy stos
    fsubp st(0),st(0)
    mov bx,1d
    call VARLOAD
    fild [calkowita]  ;st(2) - calkowita czesc liczby
    fild [dividing]  ;st(1) - podzielnik - 10
    fild [ulamek] ;st(0) - czesc ulamkowa
    mov cx,ds:[ulameklen]
  floatloop2:
    fdiv st(0),st(1)
    loop floatloop2
    cmp ds:[sign],1
    jne zapiszxmax
    fchs
  zapiszxmax:
    fstp qword ptr [xmax]
    fsubp st(0),st(0) ;zerujemy stos
    fsubp st(0),st(0)
    mov bx,2d
    call VARLOAD
    fild [calkowita]  ;st(2) - calkowita czesc liczby
    fild [dividing]  ;st(1) - podzielnik - 10
    fild [ulamek] ;st(0) - czesc ulamkowa
    mov cx,ds:[ulameklen]
  floatloop3:
    fdiv st(0),st(1)
    loop floatloop3
    cmp ds:[sign],1
    jne zapiszymin
    fchs
  zapiszymin:
    fstp qword ptr [ymin]
    fsubp st(0),st(0) ;zerujemy stos
    fsubp st(0),st(0)
    mov bx,3d
    call VARLOAD
    fild [calkowita]  ;st(2) - calkowita czesc liczby
    fild [dividing]  ;st(1) - podzielnik - 10
    fild [ulamek] ;st(0) - czesc ulamkowa
    mov cx,ds:[ulameklen]
  floatloop4:
    fdiv st(0),st(1)
    loop floatloop4
    cmp ds:[sign],1
    jne zapiszymax
    fchs
  zapiszymax:
    fstp qword ptr [ymax]
    fsubp st(0),st(0) ;zerujemy stos
    fsubp st(0),st(0)
    popa
    ret
TOFLOAT endp
;---------------------------
;---rysowanie zbioru-----
MANDELBROTSET proc
  entervideomode:
    push ax
    xor ax,ax
    mov al,0dh
    int 10h
    pop ax
  mandelbrot:
    pusha
    pushf
    xor cx,cx
    xor dx,dx
    verticalloop:
      cmp dx,200d
      je endmandelbrot
      horizontalloop:
        cmp cx,320d
        je endofrow
        mov ax,cx
        call calcp
        mov ax,dx
        call calcq
        call pixel
        cmp byte ptr ds:[pixelcol],1d
        je whitepixel
        xor al,al
        jmp drawpixel
      whitepixel:
        mov al,0Fh
      drawpixel:
        mov ah,0ch
        int 10h
        inc cx
        jmp horizontalloop
      endofrow:
        xor cx,cx
        inc dx
      jmp verticalloop
  endmandelbrot:
    popf
    popa
    push ax
    push dx
    mov ah,01h
    int 21h
    pop dx
    pop ax
  quitvideomode:
    push ax
    xor ax,ax
    mov al,3d
    int 10h
    pop ax
    mov ah,04ch
    int 21h
  calcp:
    mov tofpu,ax
    fld qword ptr [xmax]  ;w st(4) - xmax
    fld qword ptr [xmin]  ;w st(3) - xmin
    fild word ptr [horizontal]  ;w st(2) - rozdzielczosc x
    fild word ptr [tofpu] ;w st(1) - pozycja x
    fldz  ;st(0) - 0

    fadd st(0),st(4)  ;p=xmax
    fsub st(0),st(3)  ;p=xmax-xmin
    fmul st(0),st(1)  ;p=act(xmax-xmin)
    fdiv st(0),st(2)  ;p=act(xmax-xmin)/horizontal
    fadd st(0),st(3)  ;p=act(xmax-xmin)/horizontal + xmin
    fstp qword ptr [p]
    fsubp st(0),st(0) ;zwalnianie stosu
    fsubp st(0),st(0)
    fsubp st(0),st(0)
    fsubp st(0),st(0)
    ret

  calcq:
    mov tofpu,ax
    fld qword ptr [ymax]  ;w st(4) - ymax
    fld qword ptr [ymin]  ;w st(3) - ymin
    fild word ptr [vertical]  ;w st(2) - rozdzielczosc y
    fild word ptr [tofpu] ;w st(1) - pozycja y
    fldz  ;w st(0) - 0

    fadd st(0),st(4)  ;q=ymax
    fsub st(0),st(3)  ;q=ymax-ymin
    fmul st(0),st(1)  ;q=act(ymax-ymin)
    fdiv st(0),st(2)  ;q=act(ymax-ymin)/vertical
    fadd st(0),st(3)  ;q=act(ymax-ymin)/vertical + ymin
    fstp qword ptr [q]
    fsubp st(0),st(0) ;zwalniamy stos
    fsubp st(0),st(0)
    fsubp st(0),st(0)
    fsubp st(0),st(0)
    ret

  pixel:  ;wynik w pixelcol
    push ax
    push cx
    pushf
    mov byte ptr ds:[pixelcol],1d
    fld qword ptr [p] ;w st(7) - p
    fld qword ptr [q] ;w st(6) - q
    fldz  ;w st(5) - zmienna tmp
    fldz  ;w st(4) - x
    fldz  ;w st(3) - x*x
    fldz  ;w st(2) - y
    fldz  ;w st(1) - y*y
    fldz  ;w st(0) - dodatkowa zmienna pomocnicza do obliczen

    mov cx,1000d  ;1000 iteracji
  pixelloop:
    ;zmienna tmp
    fsub st(0),st(0)
    fadd st(0),st(3)
    fsub st(0),st(1)
    fadd st(0),st(7)
    fxch st(5)
    ;zmienna y
    fsub st(0),st(0)
    fadd st(0),st(4)
    fmul st(0),st(2)
    fadd st(0),st(0)
    fadd st(0),st(6)
    fxch st(2)
    ;mzmienna y
    fsub st(0),st(0)
    fadd st(0),st(5)
    fxch st(4)
    ;x*x+y*y
    fsub st(0),st(0)
    fadd st(0),st(4)
    fmul st(0),st(0)
    fxch st(3)
    fsub st(0),st(0)
    fadd st(0),st(2)
    fmul st(0),st(0)
    fxch st(1)
    fsub st(0),st(0)
    fadd st(0),st(3)
    fadd st(0),st(1)
    ;sprawdzamy wynik
    fcom [condition]
    fstsw ax
    sahf
    ja endpixelearly
    loop pixelloop
    mov ds:[pixelcol],1d
    jmp calcpixelend
  endpixelearly:
    mov ds:[pixelcol],0d
  calcpixelend:
    fsubp st(0),st(0) ;czyszczenie stosu - 8 razy pop
    fsubp st(0),st(0)
    fsubp st(0),st(0)
    fsubp st(0),st(0)
    fsubp st(0),st(0)
    fsubp st(0),st(0)
    fsubp st(0),st(0)
    fsubp st(0),st(0)
    popf
    pop cx
    pop ax
    ret
MANDELBROTSET endp
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
    finit
    call PARS
    call TOFLOAT
    call MANDELBROTSET
    mov ah,4ch
    int 21h
kod ends
;---koniec programu---

stos1 segment STACK
    dw 200h dup (?)
    top dw ?
stos1 ends

end start
