;Jakub 'Byakuya' Pilch
;Informatyka IEiT
;grupa4
;Program tworzy ASCII Art na podstawie 32-bajtowego klucza hex.
data segment
        tabl db 127 dup (?)             ;tablica 127 elementów po 1 bajcie (max input)
        licz dw 1                       ;licznik przeladowanych danych
        argz dw 1                       ;licznik argrumentow (oddzielonych spacjami/tabulatorem)
        lent db 4	dup     (0)     	;miara dlugosci argumentow (oraz adresy ich poczatkow)
		flaga dw 1						;flaga oczekiwania na argument.
                                        ;tablica postaci: [adres][dlugosc][adres][dlugosc]...
        binar db 16	dup     (?)         ;tablica z zapisem binarnym klucza.
        chess db 153	dup	(0)         ;szachownica 17x9
        arttab db	'.','o','+','=','*','B','O','X','@','%','&','#','/','^' ;znaki ascii
        ramaup db "|---[ASCII Art]---|$"       ;gorna ramka ASCIIart
        ramadwn db "|--[Jakub Pilch]--|$"      ;dolna ramka ASCIIart
        gon     dw      1                      ;zmienna przechowujaca chwilowe polozenie gonca.
        stopf dw 1                             ;pole zakonczenia skokow gonca glownego.
        stopfmod dw 1                          ;pole zakonczenia skokow gonca dodatkowego.
        komu1 db "Blad danych: zla liczba argumentow (oczekiwano2).$" ;komunikat bledu 1.
        komu2 db "Blad danych: arg1 jest rozny od {0,1} lub arg2 jest rozny od [0,...,F].$"
        komu3 db "Blad danych: zle dlugosci argumentow.$"
data ends
stack segment stack
        dw      100 dup (?)                     ;stos 100 * 2 bajty
top     dw      ?                               ;wierzcholek stosu
stack ends
code segment
        ;==============================LOADER===========================================
         LOADER proc                            ;laduje argumenty do tabl
                                                ;seg tablicy wejsciowej w ES
                                                ;seg danych w DS
                push ax                         ;ladowanie rejestrow na stos
                push bx                         ;celem przywrocenia ich na koncu
                push cx                         ;procedury
                push dx
                mov di,offset tabl              ;początek docelowej tablicy
                mov si,82h                      ;w 81h jest spacja
                mov ch,byte ptr es:[80h]        ;licznik argumentow z wiersza polecen
                ;-----------------------------------------------
                cmp ch,0d                       ;jesli wywolano bez argumentow
                JE  stoper                      ;skocz na koniec
                cmp ch,1d                       ;jesli wywolano z jednym argumentem
                JE  stoper                      ;czyli spacja, skocz na koniec
                ;-----------------------------------------------
                mov ax,0                        ;zerowanie licznika przeniesionych danych
                mov ds:[licz],ax                ;licznik przeniesionych arg. wyzerowany
                mov ax,0                        ;poczatkowa ilosc argumentow.
                mov ds:[argz],ax                ;licznik arg. oddzielonych bialym znakiem =0.
                mov dx,1d
                mov ds:[flaga],dx               ;flaga oczekiwania=TRUE.
                mov bx,offset lent              ;offset tablicy dlugosci argumentow do BX.
                dec bx                          ;oczekujemy "przed" tablica na pierwszy arg.
                ;-----------------------------------------------
        whspace:
                cmp ch,1d                       ;czy juz nie ma czego przenosic?
                JE  stoper                      ;jeśli tak, skocz do stoper
                mov ah,es:[si]                  ;przenosimy porownywany el. do ah
                cmp ah,20h                      ;czy wczytany znak to spacja?
                JNE whtab                       ;jesli nie, skocz do whtab.
                inc si                          ;jestli tak to przesun offset wejscia
                dec ch                          ;zmniejsz licznik arg. do przeniesienia
                mov dx,1d
                mov ds:[flaga],dx               ;flaga oczekiwania=TRUE.
                JMP whspace                     ;sprawdzamy od nowa
                ;-----------------------------------------------
        whtab:
                cmp ah,9h                       ;czy wczytany znak to tabulacja?
                JNE finish                      ;jesli nie, skocz do finish
                inc si                          ;jesli tak, przesun offset wejscia
                dec ch                          ;zmniejsz licznik arg. do przeniesienia
                mov dx,1d
                mov ds:[flaga],dx  				;flaga oczekiwania=TRUE.
                JMP whspace                     ;i skok do sprawdzania spacji
                ;-----------------------------------------------
        finish:
                mov ds:[di],ah                  ;przerzut do tablicy docelowej
                inc si                          ;przesuwamy offset wejscia
                dec ch                          ;zmniejszamy licznik arg. do przeniesienia
                inc ds:[licz]                   ;zwiekszamy licznik przeniesionych argumentow
				cmp ds:[flaga],1d               ;czy oczekiwano na argument?
				JNE conti                       ;jesli nie, kontynuuj przeladowanie.
				mov dx,0d                       ;jesli tak:
				mov ds:[flaga],dx               ;flaga oczekiwania=FALSE.
				inc ds:[argz]                   ;zwieksz licznik argumentow
				mov dx,3d
                cmp ds:[argz],dx                ;porownanie z limitem argumentow
                JA argerr                   	;jesli przekroczony, skok do komuniaktu o bledzie.
                inc bx                      	;jesli nie, przesuwamy sie w tablicy [lent].
                mov [bx],di             		;jako poczatek kolejnego argumentu: aktualne polozenie w [tabl]
                inc bx                      	;przesuwamy sie do licznika dlugosci kolejnego argumentu[lent]
            conti:
                inc di                          ;przesuwamy sie w tablicy docelowej
                mov ax,1d
                add [bx],ax                  	;zwiekszamy licznik dlugosci argumentu.
                JMP whspace                 	;i sprawdzamy kolejny znak
                ;-------------Powrot do programu----------------------
                stoper:
                pop dx                  ;przywracamy rejestry
                pop cx
                pop bx
                pop ax
                ret                     ;powrot do programu
        LOADER endp
     ;=========================CHECKUP========================================
		CHECKUP proc             ;procedura CHECKUP sprawdza poprawnosc
				push ax          ;danych przeniesionych do tablicy [tabl]
				push bx          ;przez procedure LOADER pod katem
				push cx          ;ilosci,dlugosci oraz poprawnosci argumentow.
				push dx          ;dodatkowo zamienia znaki w tabl
								 ;na liczby HEX (0-15).
				;-------------Sprawdzenie ilosci argumentow---------------
				cmp ds:[argz],2         ;sprawdzenie, czy wywolano z wlasciwa iloscia argumentow
				JNE argerr              ;jesli nie, skaczemy do komunikatu o bledzie.
				;-------------Sprawdzenie dlugosci argumentow-------------
				mov bx,offset lent
				inc bx                  ;na drugim miejscu [lent] jest dlugosc 1. arg.
				mov cl,1h
				cmp [bx],cl             ;czy dlugosc argumentu 1 jest rowna 1
				JNE arglenerr       	;jesli nie, skocz do bledu.
				add bx,2d               ;przesuwamy sie do dlugosci kolejnego argumentu
				mov cl,32d
				cmp [bx],cl         	;czy dlugosc argumentu 2 jest rowna 32
				JNE arglenerr       	;jesli nie, skocz do bledu.
				;-------------Sprawdzenie poprawnosci argumentow----------------
				mov di,offset tabl      ;sprawdzanie pierwszego argumentu
				mov ah,49d              ;"1" w kodzie ASCII
				cmp ds:[di],ah 	        ;jezeli argument pierwszy jest wiekszy od 1
				JA  argtypeerr          ;skaczemy do komunikatu o bledzie.
				mov ah,48d              ;"0" w kodzie ASCII
				cmp ds:[di],ah          ;jezeli argument pierwszy jest mniejszy od 0
				JB  argtypeerr          ;skaczemy do komunikatu o bledzie.
				mov bx,offset lent                      ;offset [lent] do bx
				add bx,3d                               ;na 4 miejscu - dlugosc 2 argumentu
				mov cl,[bx]                             ;dlugosc drugiego argumentu do cl
				inc cl
				loadloop:                               ;sprawdzamy czy znaki w argumencie 2.
						dec cl                          ;sa typu 0-9 lub A-F lub a-f
						cmp cl,0d
						JE getback                		;jesli wszystko sprawdzone, skok do getback
						inc di
						mov ah,66h                      ;czy znak nie jest dalej niz "f"
						cmp ds:[di],ah
						JA argtypeerr              		;jesli tak - blad;
						mov ah,61h                      ;jesli "a"<=znak=<"f"
						cmp ds:[di],ah
						JAE     little                  ;skok do kategorii little
						mov ah,46h                      ;jezeli "F"<znak<"a"
						cmp ds:[di],ah
						JA  argtypeerr              	;wyjscie z bledem.
						mov ah,41h                      ;jesli "A"<=znak=<"F"
						cmp ds:[di],ah
						JAE big                         ;skok do kategorii big
						mov ah,39h                      ;jezeli "9"<znak<"A"
						cmp ds:[di],ah
						JA  argtypeerr                  ;wyjscie z bledem.
						mov ah,30h                      ;jesli znak<"0"
						cmp ds:[di],ah
						JB argtypeerr                   ;wyjscie z bledem
						JMP digits                      ;jezeli doszedl az tu, to znaczy
														;ze "0"<=znak=<"9", skok do kat. digits.
				little:
						mov al,87d
						sub ds:[di],al                  ;sprowadzamy do zakresu 10-15
						JMP loadloop                    ;sprawdzamy kolejne
				big:
						mov     al,55d
						sub ds:[di],al                  ;sprowadzamy do zakresu 10-15
						JMP loadloop                    ;sprawdzamy kolejne
				digits:
						mov al,48d
						sub ds:[di],al                  ;sprowadzamy do zakresu 0-9
						JMP loadloop                    ;sprawdzamy kolejne
				;-------------Powrot do programu----------------------
			getback:
				pop dx                      ;przywracamy rejestry
				pop cx
				pop bx
				pop ax
				ret                         ;powrot do programu
		CHECKUP endp
;================================TOBINARY=================================
		TOBINARY proc
				push ax             ;procedura zamienia argumenty z [tabl]
				push bx             ;na binarny kod (2 arg->1 bajt)
				push cx             ;ktory zapisuje w [binar]
				push dx
				;----------------------------------------------
				mov si,offset tabl            	;wskaznik w tablicy argumentow
				inc si                          ;od 2 miejsca argumenty hex.
				mov di,offset binar             ;wskaznik w docelowej tablicy binar
				mov cx,16d                      ;petla ma wykonac sie 16 razy
				binarize:
						mov al,ds:[si]          ;argument przeniesiony do AL
						inc si                  ;przesuwamy offset w tabl
						push cx
						mov cl,4d               ;przesuwamy argument (pierwszy z pary)
						shl al,cl               ;o 4 bity w lewo
						pop cx                  ;(CL konieczny - wymuszony przez skladnie)
						mov dl,al               ;przechowamy go w dl
						mov al,ds:[si]          ;ladujemy kolejny argument wejsciowy
						inc si                  ;i przesuwamy offset w tabl
						add dl,al               ;sumujemy oba argumenty, otrzymujac jeden
												;bajt danych
						mov ds:[di],dl          ;przenosimy gotowy bajt do tablicy binar
						inc di                  ;przesuwamy offset tablicy binar
				loop binarize
						;----------------------------------------------
						pop dx                  ;przywracamy rejestry do stanu
						pop cx                  ;sprzed wywolania procedury
						pop bx
						pop ax
						ret                     ;powrot do programu
		TOBINARY endp
        ;===========================MoVeUpLeft==================================
		MVUL proc
				push ax                        	;ruch do gory i w lewo
				push bx                         ;odlozenie rejestrow celem przywrocenia
				push cx                         ;ich na koncu procedury
				push dx
		;-------------------------------------------------
												;POLE GONCA w SI
				cmp si,0h                       ;jezeli goniec jest w lewym gornym rogu
				JE ULback                     	;skocz do wyjscia
				cmp si,17d                      ;jezeli goniec jest przy suficie
				JB 	LTopslide              		;to jest na polu <17, skocz do LTopslide
				sub si,17d                      ;jezeli nie to wedruje w gore o 1 pole
				mov ax,si                       ;jezeli jest przy lewej krawedzi to
				mov bl,17d                      ;reszta z dzielenia przez 17 (szerokosc)
				div bl                          ;umieszczona w rejestrze AH bedzie
				cmp ah,0d                       ;rowna 0. Jezeli to prawda,
				JE ULback                  		;skocz na koniec, ruch w gore juz wykonany.
				dec si                          ;jezeli nie, przesun sie w lewo.
				JMP ULback                      ;skok na koniec
			LTopslide:
						dec si                  ;slizg po suficie w lewo
				ULback:
						mov bx,offset chess     ;poczatek szachownicy w BX
						add bx,si               ;teraz w BX offset pola gonca
						mov ax,1d               ;zwieksz liczbe odwiedzin pola,
						add ds:[bx],ax          ;na ktorym stanal goniec
						pop dx                  ;przywroc rejestry
						pop bx
						pop cx
						pop ax
						ret                     ;powrot do programu
		MVUL endp
        ;=============================MoVeUpRight=======================
        MVUR proc
				push ax                         ;ruch do gory i w prawo
				push bx                         ;odlozenie rejestrow celem przywrocenia
				push cx                         ;ich na koncu procedury
				push dx
		;-------------------------------------------------
												;POLE GONCA w SI
				cmp si,16d                      ;jezeli goniec jest w prawym gornym rogu
				JE URback                  		;skocz do wyjscia
				cmp si,17d                      ;jezeli goniec jest przy suficie
				JB RTopslide               		;to jest na polu <17, skocz do LTopslide
				sub si,17d                      ;jezeli nie to wedruje w gore o 1 pole
				mov ax,si                       ;jezeli jest przy prawej krawedzi to
				mov bl,17d                      ;reszta z dzielenia przez 17 (szerokosc)
				div bl                          ;umieszczona w rejestrze AH bedzie
				cmp ah,16d                      ;rowna 16. Jezeli to prawda,
				JE URback                       ;skocz na koniec, ruch w gore juz wykonany.
				inc si                          ;jezeli nie, przesun sie w prawo.
				JMP URback                      ;skok na koniec
			RTopslide:
						inc si                  ;slizg po suficie w prawo
			URback:
				mov bx,offset chess     ;poczatek szachownicy w BX
				add bx,si               ;teraz w BX offset pola gonca
				mov ax,1d               ;zwieksz liczbe odwiedzin pola,
				add ds:[bx],ax          ;na ktorym stanal goniec
				pop dx                  ;przywroc rejestry
				pop bx
				pop cx
				pop ax
				ret                     ;powrot do programu
		MVUR endp
        ;=========================MoVeDownRight=========================
		MVDR proc
				push ax                           	;ruch w dol i w prawo
				push bx                             ;odlozenie rejestrow celem przywrocenia
				push cx                             ;ich na koncu procedury
				push dx
		;-------------------------------------------------
													;POLE GONCA w SI
				cmp si,152d                         ;jezeli goniec jest w prawym dolnym rogu
				JE DRback                      		;skocz do wyjscia
				cmp si,135d                         ;jezeli goniec jest przy podlodze
				JA RBotslide                   		;to jest na polu >135, skocz do RBotslide
				add si,17d                          ;jezeli nie to wedruje w dol o 1 pole
				mov ax,si                           ;jezeli jest przy prawej krawedzi to
				mov bl,17d                          ;reszta z dzielenia przez 17 (szerokosc)
				div bl                              ;umieszczona w rejestrze AH bedzie
				cmp ah,16d                          ;rowna 16. Jezeli to prawda,
				JE DRback                           ;skocz na koniec, ruch w dol juz wykonany.
				inc si                              ;jezeli nie, przesun sie w prawo.
				JMP DRback                          ;skok na koniec
			RBotslide:
				inc si                              ;slizg po podlodze w prawo
			DRback:
				mov bx,offset chess         ;poczatek szachownicy w BX
				add bx,si                   ;teraz w BX offset pola gonca
				mov ax,1d                   ;zwieksz liczbe odwiedzin pola,
				add ds:[bx],ax              ;na ktorym stanal goniec
				pop dx                      ;przywroc rejestry
				pop bx
				pop cx
				pop ax
				ret                         ;powrot do programu
		MVDR endp
        ;===========================MoVeDownLeft=============================
		MVDL proc
				push ax                   	;ruch w dol i w lewo
				push bx                     ;odlozenie rejestrow celem przywrocenia
				push cx                     ;ich na koncu procedury
				push dx
		;-------------------------------------------------
											;POLE GONCA w SI
				cmp si,136d                 ;jezeli goniec jest w lewym dolnym rogu
				JE      DLback              ;skocz do wyjscia
				cmp si,135d                 ;jezeli goniec jest przy podlodze
				JA      LBotslide           ;to jest na polu >135, skocz do RBotslide
				add si,17d                  ;jezeli nie to wedruje w dol o 1 pole
				mov ax,si                   ;jezeli jest przy lewej krawedzi to
				mov bl,17d                  ;reszta z dzielenia przez 17 (szerokosc)
				div bl                      ;umieszczona w rejestrze AH bedzie
				cmp ah,0d                   ;rowna 0. Jezeli to prawda,
				JE      DLback              ;skocz na koniec, ruch w dol juz wykonany.
				dec si                      ;jezeli nie, przesun sie w lewo.
				JMP DLback                  ;skok na koniec
			LBotslide:
					dec si              	;slizg po podlodze w lewo
			DLback:
					mov bx,offset chess     ;poczatek szachownicy w BX
					add bx,si               ;teraz w BX offset pola gonca
					mov ax,1d               ;zwieksz liczbe odwiedzin pola,
					add ds:[bx],ax          ;na ktorym stanal goniec
					pop dx                  ;przywroc rejestry
					pop bx
					pop cx
					pop ax
					ret                     ;powrot do programu
		MVDL endp
        ;===============================GETBIT=============================
		GETBIT proc
				push ax                     ;procedura analizuje bity klucza z [binar]
				push bx                     ;i wykonuje ruchy gonca
				push cx
				push dx
				;---------------------------------------
				mov di,offset binar         ;poczatek [binar] do DI
				mov cx,16d                  ;16 bajtow do przeanalizowania
				mov si,76d                  ;goniec
		bitloop:
				mov al,ds:[di]              ;8 bitow klucza do AL
				inc di
				mov dx,5d                   ;licznik par bitow (dec na starcie)
				startbit:
				dec dx                      ;zmniejszenie licznika
				cmp dx,0d                   ;czy juz sprawdzono wszystkie bity?
				JE stopbit                  ;jezeli tak, koniec bajtu
											;analizujemy od najmlodszego bitu
				shr al,1d                   ;przesuwamy 1b w prawo i sprawdzajmy flage CF
				JC      right               ;jezeli byla to jedynka - do ruchu w prawo
				JMP left                    ;jezeli nie - do ruchu w lewo
				right:
						shr al,1d           ;sprawdzamy drugi bit
						JC      Rdown       ;jezeli to jedynka - ruch bedzie w dol
						JMP Rup             ;jezeli zero - ruch w gore
				left:
						shr al,1d           ;sprawdzamy drugi bit
						JC      Ldown       ;jezeli 1 - ruch w dol
						JMP     Lup         ;jezeli 0 - ruch w gore
						Rdown:              ;wykonanie ruchu w odpowiednim kierunku
								call MVDR   ;i powrot do startbit
								JMP startbit
						Rup:
								call MVUR
								JMP startbit
						Ldown:
								call MVDL
								JMP startbit
						Lup:
								call MVUL
								JMP startbit
		stopbit:
				loop bitloop                ;przesuwamy sie do kolejnego bajtu
				mov ds:[stopf],si           ;pole zakonczenia skokow zapisane
				pop dx                      ;przywrocenie rejestrow
				pop cx
				pop bx
				pop ax
				ret                         ;powrot do programu
		GETBIT endp
        ;============================MAKEART===============================
		MAKEART proc
				push ax                   	;zamiana licznikow odwiedzin pola
				push bx                     ;na znaki ASCII w tablicy [chess]
				push cx
				push dx
		;-----------------------------------------
				mov si,offset arttab        ;tablica znakow ASCII
				mov di,offset chess         ;szachownica
				dec di                      ;inc na poczatku petli
				mov cx,154d                 ;153 pola do konwersji (dec na poczatku)
		next:
				dec cx                      ;zmniejsz licznik pozostalych konwersji.
				cmp cx,0d                   ;jezeli wszystko przekonwertowane
				JE convret                  ;skocz do convret
				inc di                      ;przesun sie na kolejne pole [chess]
				mov al,ds:[di]
				cmp al,0d                   ;jezeli zero odwiedzin
				JE      next                ;pozostaw puste pole (NULL)
				mov al,ds:[di]
				cmp al,13d                  ;jezeli wiecej niz 13 odwiedzin
				JA      overup              ;skocz do overup
				xor bx,bx                   ;upewnij sie, ze w BX jest null
				mov bl,ds:[di]              ;liczba odwiedzin do BL
				mov dh,ds:[si+bx-1d]        ;adekwatny znak do DH
				mov ds:[di],dh              ;Znak z DH do chess
				JMP next
		overup:
				mov al,"^"                  ;powyzej 13 odwiedzin
				mov ds:[di],al              ;wstawiamy "^"
				JMP next
		convret:
				mov bx,offset chess        	;offset szachownicy do BX
				add bx,ds:[stopf]           ;teraz jest tam pole zakonczenia skokow.
				mov al,"E"
				mov ds:[bx],al              ;na pole koncowe wstawiamy "E"
				mov di,offset chess         ;poczatek chess do DI
				mov al,"S"
				mov ds:[di+76d],al          ;na 76 pole wstawiamy "S" (poczatek)
				;----------------------------------------------
				pop dx                      ;przywrocenie rejestrow
				pop cx                      ;i powrot
				pop bx
				pop ax
				ret
		MAKEART endp
        ;==============================PRINTER=============================
		PRINTER proc                     	;procedura wypisujaca zawartosc
				push ax                     ;tablicy na ekran
				push bx
				push cx
				push dx
				mov cx,9d                   ;9 wierszy (po 17 elementow kazdy)
				mov di,offset chess         ;ustawiamy DI na poczatek tablicy [chess]
;----------------------------------------------
				mov dx,offset ramaup    	;wypisanie górnej linii ramki
				mov ah,9
				int 21h
				mov dx,10d                  ;"wypisujemy" znak nowej linii.
				mov ah,2
				int 21h
		petla:
				mov bx,0d                   ;licznik wydrukowanych elementow wiersza.
				mov dx,"|"
				mov ah,2
				int 21h                     ;drukowanie ramki.
		tutaj:
				cmp bx,17d                  ;jezeli wydrukowano juz 17 elementow
				JE nowalinia                ;skocz do nowalinia.
				inc bx                      ;zwieksz licznik drukowanych elementow w wierszu.
				mov dx,ds:[di]              ;ladujemy element z tablicy do DX
				mov ah,2                	;przerwanie DOS nr 2 wypisuje znak z DX.
				int 21h                     ;w tym wypadku sa tam "gotowe" znaki ASCII.
				inc di                      ;przesuwamy offset (w tablicy)
				JMP tutaj                   ;skok do kolejnego elementu z wiersza
		nowalinia:
				mov dx,"|"
				mov ah,2
				int 21h                     ;drukowanie ramki.
				mov dx,10d                  ;"wypisujemy" znak nowej linii.
				mov ah,2
				int 21h
				loop petla                  ;powtarzamy dla wszystkich wierszy(licznik w CX).
				mov dx,offset ramadwn   	;wypisanie dolnej linii ramki
				mov ah,9
				int 21h
		;-------------------------------------------
				pop dx                      ;przywrocenie rejestrow
				pop cx
				pop bx
				pop ax
				ret                         ;powrot do programu
		PRINTER endp
        ;===============================GETMODIFIEDBIT================================
		GETMODIFIEDBIT proc
				push ax                     ;procedura analizuje bity klucza z [binar]
				push bx                     ;i wykonuje ruchy gonca
				push cx
				push dx
				;---------------------------------------
				mov di,offset binar         ;poczatek [binar] do DI
				mov cx,16d                  ;16 bajtow do przeanalizowania
				mov bx,76d                  ;goniec glowny
				mov ds:[gon],bx
				mov si,16d                  ;goniec dodatkowy
		bitloopmod:
				mov al,ds:[di]              ;8 bitow klucza do AL
				inc di
				mov dx,5d                   ;licznik par bitow (dec na starcie)
		startbitmod:
				dec dx                      ;zmniejszenie licznika
				cmp dx,0d                   ;czy juz sprawdzono wszystkie bity?
				JE stopbitmod               ;jezeli tak, koniec bajtu
				push di                     ;chwilowy bufor w di
				mov di,si               	;zamiana goncow:
				mov si,ds:[gon]         	;teraz ruch wykonuje drugi goniec
				mov ds:[gon],di             ;a polozenie pierwszego zachowane w [gon]
				pop di
											;analizujemy od najmlodszego bitu
				shr al,1d                   ;przesuwamy 1b w prawo i sprawdzajmy flage CF
				JC      rightmod            ;jezeli byla to jedynka - do ruchu w prawo
				JMP leftmod                 ;jezeli nie - do ruchu w lewo
				rightmod:
						shr al,1d           ;sprawdzamy drugi bit
						JC      Rdownmod    ;jezeli to jedynka - ruch bedzie w dol
						JMP Rupmod          ;jezeli zero - ruch w gore
				leftmod:
						shr al,1d           ;sprawdzamy drugi bit
						JC      Ldownmod    ;jezeli 1 - ruch w dol
						JMP     Lupmod      ;jezeli 0 - ruch w gore
						Rdownmod:           ;wykonanie ruchu w odpowiednim kierunku
								call MVDR   ;i powrot do startbit
								JMP startbitmod
						Rupmod:
								call MVUR
								JMP startbitmod
						Ldownmod:
								call MVDL
								JMP startbitmod
						Lupmod:
								call MVUL
								JMP startbitmod
		stopbitmod:
				loop bitloopmod              ;przesuwamy sie do kolejnego bajtu
				mov ds:[stopfmod],si         ;pole zakonczenia skokow dodatkowych zapisane
											 ;zakonczy dodatkowy: wykonuje on parzyste ruchy
											 ;a ruchow jest 64 (16 bajtow x 4 pary bitow)
				mov bx,ds:[gon]
				mov ds:[stopf],bx            ;pole zakonczenia glownego gonca zapisane.
				;-----------------------------------------
				pop dx                       ;przywrocenie rejestrow
				pop cx
				pop bx
				pop ax
				ret                          ;powrot do programu
		GETMODIFIEDBIT endp
        ;=============================================================================
		CHOOSEVER proc
				push ax                      ;wybor wersji programu
				push bx                      ;(1 goniec/2 gonce)
				push cx
				push dx
				;------------------------------------
				mov di,offset tabl
				xor bx,bx
				mov bl,ds:[di]               ;pobieramy argument modyfikacji
				cmp bl,49d                   ;czy jest to 1 w kodzie ASCII?
				JE modified                  ;jesli tak: wersja modyfikowana
				call GETBIT                  ;jesli nie: wersja podstawowa
				call MAKEART                 ;zamiana liczby odwiedzin na znaki ASCII
				JMP versionret
		modified:
				call GETMODIFIEDBIT
				call MAKEART                 ;zamiana liczby odwiedzin na znaki ASCII
				mov di,offset chess          ;poczatek chess do DI
				mov al,"S"
				mov ds:[di+16d],al           ;na 16 pole wstawiamy "S" (poczatek gonca 2)
				mov al,"E"
				mov bx,ds:[stopfmod]         ;na pole zakonczenia gonca 2 wstawiamy "E"
				mov ds:[di+bx],al
				;------------------------------------
		versionret:
				pop dx                       ;przywrocenie rejestrow
				pop cx
				pop bx
				pop ax
				ret                          ;powrot do programu
		CHOOSEVER endp
        ;==============================================================================
START:
        mov bx,ds
                                                ;Program Segment Prefix do BX
        mov es,bx                               ;przenosimy segment do ES dla procedury
        mov ax,data                             ;segment danych przeladowany
        mov ds,ax                               ;do DS
                ;----------------------------------------------------
                mov ax,seg stack                ;inicjalizacja stosu
                mov ss,ax
                mov sp,offset top
                ;----------------------------------------------------
        call LOADER                             ;procedura loader-zaladuje arg. do tabl.
                call CHECKUP
                call TOBINARY
                call CHOOSEVER
                call PRINTER
        mov ah,4ch                              ;zakonczenie programu.
        int 21h
        ;****************BLAD ilosci argumentow*************************
argerr:
        mov dx,offset komu1             		;napis komunikatu do rejestru DX
        mov ah,9                                ;przerwanie nr 9 wypisuje lancuch zakonczony $
        int 21h                                 ;komunikat o zlej liczbie argumentow
        mov ah,4ch                              ;i zakonczenie programu.
        int 21h
        ;****************BLAD typu argumentow*************************
argtypeerr:
        mov dx,offset komu2             		;napis komunikatu do rejestru DX
        mov ah,9                                ;przerwanie nr 9 wypisuje lancuch zakonczony $
        int 21h                                 ;komunikat o zlym typie argumentow (zakres danych)
        mov ah,4ch                              ;i zakonczenie programu.
        int 21h
        ;****************BLAD dlugosci argumentow*************************
arglenerr:
        mov dx,offset komu3             ;napis komunikatu do rejestru DX
        mov ah,9                        ;przerwanie nr 9wypisuje lancuch zakonczony $
        int 21h                         ;komunikat o zlej dlugosci argumentow
        mov ah,4ch                      ;i zakonczenie programu.
        int 21h
code ends
end START
