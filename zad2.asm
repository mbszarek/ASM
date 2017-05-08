 ; Mateusz Szarek - CRC16 calculator
 ; Computer Science student
 ; Faculty of Computer Science, Electronics and Telecommunications
assume cs:kod,ds:dane,ss:stos1

polycrc EQU 8005h  ;wielomian CRC

dane segment
  args db 127 dup ('$')
  argc dw 0 ;ilosc argumentow
  argv dw 20 dup (?) ;offsety argumentow
  arglen dw 20 dup (0) ;dlugosci argumentow
  flaga dw 1 ;flaga znaku
  proption dw 0  ;modyfikacja, 1 - z, 0 - bez
  input1 db 127 dup (?)  ;nazwa pierwszego pliku zakonczona 0 (readonly)
  input1handle dw ?
  input2 db 127 dup (?)  ;nazwa drugiego pliku zakonczona 0 (read&write)
  input2handle dw ?
  buffer db 500 dup ("$") ;bufor odczytu
  bufferlength dw 1 ;dlugosc odczytu
  bufferposition dw 1 ;aktualna pozycja w buforze
  alreadyread dw 0  ;ile odczytanych
  eof db 1  ;flaga konca pliku
  line db 200 dup (?) ;tablica z linia do zapisania
  crc dw 256 dup (0) ;tablica z wartosciami CRC
  crcval dw 0 ;zmienna do obliczania crc
  tmpcrcval dw 0  ;pomocnicza zmienna do obliczania crc
  readcrc dw 1  ;suma CRC z pliku odczytanego
  alreadyreadcrc dw 1 ;ile odczytanch znakow z pliku CRC
  eofcrc db 1 ;flaga konca pliku z CRC
  crcsavetable db 6 dup (?) ;tablica ze znakami CRC
  rev dw 1  ;odwracana liczba
  bitstorev dw 0  ;ilosc bitow do odwrocenia
  tmprev dw 1 ;zmienna pomocna przy obliczaniu tablicy CRC
  savebuffer dw 120 dup (0) ;bufor zapisu
  savebufferposition dw 1 ;pozycja bufora zapisu
  savebufferchars dw 1  ;ilosc znakow zaladowanych do bufora zapisu
  crcbuffer db 60 dup (0) ;bufor odczytu CRC
  crcbufferposition dw 1  ;pozycja bufora odczytu drugiego pliku
  crcbufferchars dw 1 ;ilosc odczytanych znakow z drugiego pliku
  crcbufferlength dw 1  ;ilosc wczytanych znakow
  linecounter dw 0  ;numer aktualnie czytanej linii przy wersji sprawdzania CRC
  multiplier db 0 ;ilosc bitow do przesuniecia
  numtoprint dw ?
  err1 db 'No arguments!',0ah,0dh,'$'
  err2 db 'Too low arguments!',0ah,0dh,'$'
  err3 db 'Too much arguments!',0ah,0dh,'$'
  err4 db 'Wrong , only -v is available!',0ah,0dh,'$'
  err5 db 'Cannot open first file!',0ah,0dh,'$'
  err6 db 'Cannot create second file!',0ah,0dh,'$'
  err7 db 'Cannot open second file!',0ah,0dh,'$'
  err8 db 'Cannot save to file!',0ah,0dh,'$'
  err9 db 'Cannot read from first file!',0ah,0dh,'$'
  err10 db 'Cannot read CRC from second file',0ah,0dh,'$'
  err11 db 'CRC from first file does not match the CRC contained in second file!',0ah,0dh,'$'
  succ db 'CRC calculation success!',0ah,0dh,'$'
  cmpsucc db 'CRC comparision successful!',0ah,0dh,'$'
  debug db 'XDXDXD',0ah,0dh,'$'
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
    int 21h
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
    pop di
    pop si
    pop cx
    pop ax
    ret
  fillwithmod:
    mov si,ds:[argv+2]
    mov di,offset input1
    xor cx,cx
    mov cx,ds:[arglen+2]
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
    push cx
    push dx
    mov dx,offset input1
    xor ax,ax
    mov ah,03dh
    int 21h
    jc errorfile1
    mov ds:[input1handle],ax
    cmp ds:[proption],1
    je openwithmod
    xor cx,cx
    xor ax,ax
    mov al,01d
    mov dx,offset input2
    mov ah,03ch
    int 21h
    jc errorfile2create
    mov ds:[input2handle],ax
    jmp openfileret
  openwithmod:
    mov dx,offset input2
    xor ax,ax
    mov ah,3dh
    int 21h
    jc errorfile2open
    mov ds:[input2handle],ax
  openfileret:
    pop dx
    pop cx
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
  errorfile2create:
    push ax
    push dx
    mov dx,offset err6
    mov ah,09h
    int 21h
    pop dx
    pop ax
    jmp fileerrorend
  errorfile2open:
    push ax
    push dx
    mov dx,offset err7
    mov ah,09h
    int 21h
    pop dx
    pop ax
    jmp fileerrorend
  fileerrorend:
    pop dx
    pop cx
    pop ax
    mov ah,04ch
    int 21h
OPENFILES endp
;---------------------------
;---odczyt z pliku---
READFILE proc
    push ax
    push bx
    push cx
    push dx
    xor ax,ax
    xor cx,cx
    mov ds:[eof],0
    mov ds:[bufferlength],0d
    mov bx,ds:[input1handle]
    mov cx,500d
    mov dx,offset buffer
    mov ah,03fh
    int 21h
    jc readerror
    mov ds:[bufferlength],ax
    cmp ax,0d
    jne endofread
    mov ds:[eof],1
  endofread:
    mov ds:[bufferposition],offset bufferposition
    pop dx
    pop cx
    pop bx
    pop ax
    ret
  readerror:
    mov dx,offset err9
    mov ah,09h
    int 21h
    pop dx
    pop cx
    pop bx
    pop ax
    mov ah,04ch
    int 21h
READFILE endp
;----------------------
;---wczytywanie znaku---
GETCHAR proc
    push ax
    push bx
    push cx
    push dx
  getcharbreakpoint:
    mov di,ds:[bufferposition]
    cmp ds:[alreadyread],0d
    je runbuffer
    mov al,ds:[di]
    mov ds:[si],al
    inc di
    inc si
    dec ds:[alreadyread]
    mov ds:[bufferposition],di
  endgettingchar:
    pop dx
    pop cx
    pop bx
    pop ax
    ret
  runbuffer:
    call READFILE
    cmp ds:[eof],1d
    je endgettingchar
    mov ax,ds:[bufferlength]
    mov ds:[alreadyread],ax
    jmp getcharbreakpoint
GETCHAR endp
;-----------------------
;---wczytywanie linii---
GETLINE proc
    push ax
    push bx
    push cx
    push dx
    mov si,offset line
  startgettingline:
    call GETCHAR
    cmp ds:[eof],1d
    je finishline
    mov ax,10d
    cmp byte ptr ds:[si-1],al
    je endgettingline
    jmp startgettingline
  finishline:
    mov ax,13d
    mov byte ptr ds:[si],al
  endgettingline:
    inc si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
GETLINE endp
;----------------------
;---odwracanie bitow---
REVERSEBITS proc
    push ax
    push cx
    push dx
    xor ax,ax
    xor cx,cx
    xor dx,dx
    mov ax,ds:[rev]
    mov ds:[rev],0
    mov dx,ds:[bitstorev]
  revloop:
    mov cl,1d
    shl ds:[rev],cl
    shr ax,cl
    jc addition
    dec dx
    cmp dx,0d
    jne revloop
    jmp revend
  addition:
    add ds:[rev],1
    dec dx
    cmp dx,0d
    jne revloop
    jmp revend
  revend:
    pop dx
    pop cx
    pop ax
    ret
REVERSEBITS endp
;------------------------------
;---wypelnianie tablicy CRC---
FILLCRCTABLE proc
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    xor dx,dx
    xor cx,cx
    mov dl,1d
    mov cl,15d
    shl dx,cl
    xor si,si
    xor cx,cx
    mov cx,256d
  crcmainloop:
    xor ax,ax
    mov ax,si
    mov ds:[rev],ax
    mov ds:[bitstorev],8d
    call REVERSEBITS
    push cx
    xor cx,cx
    mov cl,8d
    shl ds:[rev],cl
    pop cx
    xor bx,bx
    mov bx,8d
  crcinnerloop:
    dec bx
    push ax
    mov ax,ds:[rev]
    mov ds:[tmprev],ax
    pop ax
    and ds:[tmprev],dx
    cmp ds:[tmprev],0d
    jne resnotzero
    push cx
    xor cx,cx
    mov cl,1d
    shl ds:[rev],cl
    pop cx
    cmp bx,0d
    jne crcinnerloop
    jmp innerloopfinish
  resnotzero:
    push cx
    xor cx,cx
    mov cl,1d
    shl ds:[rev],cl
    pop cx
    xor ds:[rev],polycrc
    cmp bx,0d
    jne crcinnerloop
    jmp innerloopfinish
  innerloopfinish:
    mov ds:[bitstorev],16d
    call REVERSEBITS
    mov ax,ds:[rev]
    xor di,di
    mov di,offset crc
    add di,si
    add di,si
    mov ds:[di],ax
    inc si
    loop crcmainloop
    jmp fillcrcend
  fillcrcend:
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
FILLCRCTABLE endp
;---------------------------
;---obliczanie sumy CRC dla linii---
COUNTCRC proc
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    xor ax,ax
    mov ds:[crcval],ax
    mov ds:[crcval],0ffffh
    mov si,offset line
  crcbreakpoint:
    mov ax,13d
    cmp byte ptr ds:[si],al
    je finishcrc
    mov ax,ds:[crcval]
    push cx
    xor cx,cx
    mov cl,8d
    shr ax,cl
    pop cx
    mov ds:[tmpcrcval],ax
    xor dx,dx
    mov dx,ds:[si]
    xor ds:[tmpcrcval],dx
    and ds:[tmpcrcval],0ffh
    inc si
    mov di,ds:[tmpcrcval]
    add di,ds:[tmpcrcval]
    add di,offset crc
    mov cl,8d
    shr ds:[crcval],cl
    mov dx,ds:[di]
    xor ds:[crcval],dx
    jmp crcbreakpoint
  finishcrc:
    mov cx,0ffffh
    push ax
    mov ax,ds:[crcval]
    xor ax,cx
    mov ds:[crcval],ax
    pop ax
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
COUNTCRC endp
;----------------------
;---zamiana wartosci crc na gotowy do zapisu string---
CRCTOSAVE proc
    push ax
    push bx
    push cx
    push dx
    xor cx,cx
    mov cx,4d
    mov ax,ds:[crcval]
    mov bx,10h
  crcsaveloop:
    xor dx,dx
    div bx
    push dx
    loop crcsaveloop
    mov si,offset crcsavetable
    mov cx,4d
  startsaving:
    pop dx
    cmp dx,9d
    ja bigalpha
    add dx,48d
    jmp endsavingcrc
  bigalpha:
    add dx,55d
  endsavingcrc:
    mov ds:[si],dl
    inc si
    loop startsaving
    mov ax,13d
    mov byte ptr ds:[si],al
    inc si
    mov ax,10d
    mov byte ptr ds:[si],al
    pop dx
    pop cx
    pop bx
    pop ax
    ret
CRCTOSAVE endp
;--------------------
;---zapis do pliku---
SAVETOFILE proc
    push ax
    push bx
    push cx
    push dx
    mov bx,ds:[input2handle]
    mov cx,ds:[savebufferchars]
    mov ds:[numtoprint],cx
    call PRINTNUM
    mov dx,offset savebuffer
    mov ah,40h
    int 21h
    jc saveerror
    pop dx
    pop cx
    pop bx
    pop ax
    ret
  saveerror:  ;blad zapisu
    mov dx,offset err8
    mov ah,09h
    int 21h
    pop dx
    pop cx
    pop bx
    pop ax
    mov ah,04ch
    int 21h
SAVETOFILE endp
;-----------------------
;---odczytuje crc pliku i zapisuje do drugiego---
GETFILECRC proc
    push ax
    push bx
    push cx
    push dx
    mov ds:[eof],0d
    mov ds:[alreadyread],0d
    mov ds:[savebufferposition],offset savebuffer
    mov ds:[savebufferchars],0d
  begingetting:
    cmp ds:[eof],0d
    jne endgetting
    call GETLINE
    call COUNTCRC
    call SAVEBUF
    jmp begingetting
  endgetting:
    call SAVETOFILE
    pop dx
    pop cx
    pop bx
    pop ax
    ret
GETFILECRC endp
;-------------------------
;---pobranie jednej linii z pliku CRC---
GETONECRCLINE proc
    push ax
    push bx
    push cx
    push dx
  beginloading:
    cmp ds:[alreadyreadcrc],0d
    je loadcrc
    mov cx,6d
    mov si,offset crcsavetable
    mov di,ds:[crcbufferposition]
  getcrcloop:
    mov al,ds:[di]
    mov ds:[si],al
    inc si
    inc di
    dec ds:[alreadyreadcrc]
    loop getcrcloop
    mov ds:[crcbufferposition],di
  endgettingcrc:
    pop dx
    pop cx
    pop bx
    pop ax
    ret
  loadcrc:
    call CRCREADER
    cmp ds:[eofcrc],1d
    je endgettingcrc
    mov ax,ds:[crcbufferlength]
    mov ds:[alreadyreadcrc],ax
    jmp beginloading
GETONECRCLINE endp
;-------------------------
;---"odpakowanie" CRC---
UNCRC proc
    push ax
    push bx
    push cx
    push dx
    mov cx,4d
    xor ax,ax
    mov ds:[readcrc],ax
    mov ds:[multiplier],0d
  beginuncrc:
    mov si,offset crcsavetable
    dec si
    add si,cx
    xor ax,ax
    mov al,ds:[si]
    cmp ax,65d
    jb decimal
    sub ax,55d
    jmp uncrcbreakpoint
  decimal:
    sub ax,48d
  uncrcbreakpoint:
    push cx
    xor cx,cx
    mov cl,ds:[multiplier]
    shl ax,cl
    add ds:[readcrc],ax
    xor ax,ax
    add ds:[multiplier],4
    pop cx
    loop beginuncrc
    pop dx
    pop cx
    pop bx
    pop ax
    ret
UNCRC endp
;---------------------------
;---porownanie CRC w obu plikach---
COMPARECRCS proc
    push ax
    push bx
    push cx
    push dx
    mov ds:[linecounter],1d
    mov ds:[eofcrc],0d
    mov ds:[alreadyreadcrc],0d
    mov ds:[eof],0d
    mov ds:[alreadyreadcrc],0d
  cmpbegin:
    call GETLINE
    call COUNTCRC
    call GETONECRCLINE
    cmp ds:[eofcrc],1d
    je endcmp
    call UNCRC
    mov dx,ds:[readcrc]
    mov ax,ds:[crcval]
    mov ds:[numtoprint],ax
    call PRINTNUM
    push ax
    push dx
    mov ah,02h
    mov dl,0ah
    int 21h
    pop dx
    pop ax
    mov ds:[numtoprint],dx
    call PRINTNUM
    push ax
    push dx
    mov ah,02h
    mov dl,0ah
    int 21h
    pop dx
    pop ax
    push ax
    push dx
    mov dl,ds:[eof]
    add dl,48d
    mov ah,02h
    int 21h
    mov dl,20h
    mov ah,02h
    int 21h
    mov dl,ds:[eofcrc]
    add dl,48d
    mov ah,02h
    int 21h
    mov dl,20h
    mov ah,02h
    int 21h
    mov dl,0ah
    mov ah,02h
    int 21h
    pop dx
    pop ax
    cmp dx,ax
    jne mismatch
    inc ds:[linecounter]
    jmp cmpbegin
  mismatch:
    mov dx,offset err11
    mov ah,09h
    int 21h
    mov ah,04ch
    int 21h
  endcmp:
    cmp ds:[eof],0d
    jne mismatch
    pop dx
    pop cx
    pop bx
    pop ax
    ret
COMPARECRCS endp
;---------------------------
CRCREADER proc
    push ax
    push bx
    push cx
    push dx
    mov ds:[eofcrc],0d
    mov ds:[crcbufferlength],0d
    mov bx,ds:[input2handle]
    mov cx,60d
    mov dx,offset crcbuffer
    mov ah,03fh
    int 21h
    jc crcreaderror
    mov ds:[crcbufferlength],ax
    cmp al,3d
    ja finishcrcreading
    mov ds:[eofcrc],1d
  finishcrcreading:
    mov ds:[crcbufferposition],offset crcbuffer
    pop dx
    pop cx
    pop bx
    pop ax
    ret
  crcreaderror:
    mov ah,09h
    mov dx,offset err10
    int 21h
    pop dx
    pop cx
    pop bx
    pop ax
    mov ah,04ch
    int 21h
CRCREADER endp
;---------------------------
;---zapis buforu do pliku---
SAVEBUF proc
    push ax
    push bx
    push cx
    push dx
    cmp ds:[savebufferchars],119d
    ja saveit
    call CRCTOSAVE
    mov cx,6d
    mov si,offset crcsavetable
    mov di,ds:[savebufferposition]
  buffersaver:
    mov al,ds:[si]
    mov ds:[di],al
    inc si
    inc di
    inc ds:[savebufferchars]
    loop buffersaver
    mov ds:[savebufferposition],di
    pop dx
    pop cx
    pop bx
    pop ax
    ret
  saveit:
    call SAVETOFILE
    mov ds:[savebufferchars],0d
    mov ds:[savebufferposition],offset savebuffer
    jmp buffersaver
SAVEBUF endp
;-------------------------------
;---w zaleznosci od opcji wykonuje odpowiednie operacje---
MODIFICATION proc
    push ax
    push bx
    push cx
    push dx
    cmp ds:[proption],1d
    je executewithmod
    call GETFILECRC
    mov dx,offset succ
    jmp modifend
  executewithmod:
    call COMPARECRCS
    mov dx,offset cmpsucc
    jmp modifend
  modifend:
    mov ah,09h
    int 21h
    pop dx
    pop cx
    pop bx
    pop ax
    ret
MODIFICATION endp
;-----------------------
;---zamykanie plikow---
CLOSEFILES proc
    push ax
    push bx
    push dx
    mov bx,ds:[input1handle]
    mov ah,03eh
    int 21h
    mov bx,ds:[input2handle]
    mov ah,03eh
    int 21h
    pop dx
    pop bx
    pop ax
    ret
CLOSEFILES endp
;---------------------------
PRINTNUM proc
    push ax
    push bx
    push cx
    push dx
    xor bx,bx
    mov bx,10d
    mov ax,ds:[numtoprint]
    xor cx,cx
  printdiv:
    xor dx,dx
    div bx
    push dx
    inc cx
    cmp ax,0
    jne printdiv
  printit:
    pop dx
    add dl,48d
    mov ah,02h
    int 21h
    loop printit
    pop dx
    pop cx
    pop bx
    pop ax
    ret
PRINTNUM endp
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
    call OPENFILES
    call FILLCRCTABLE
    call MODIFICATION
    call CLOSEFILES
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
