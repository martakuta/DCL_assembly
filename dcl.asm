SYS_WRITE equ 1
STDOUT    equ 1
SYS_READ equ 0
STDIN    equ 0
SYS_EXIT  equ 60
SIGNS equ 42

global _start                           ; Wykonanie programu zaczyna się od etykiety _start

section .bss
        permut_l resb SIGNS
        permut_r resb SIGNS
        permut_t resb SIGNS
        klucz_l resb 1
        klucz_r resb 1
        tablica resb SIGNS

section .rodata

; znak nowej linii
new_line db `\n`

;-------------------------------------------------------------------------------;

section .text

wczytaj_znak:
        mov     rax, SYS_READ
        mov     rdi, STDIN
        mov     rdx, 1
        syscall
        ret

wypisz_permutacje:
        mov     rax, SYS_WRITE
        mov     rdi, STDOUT
        mov     rdx, SIGNS
        syscall

        mov     rsi, new_line           ; Wypisz znak nowej linii.
        call    wypisz_znak
        ret

wypisz_znak:
        mov     rax, SYS_WRITE
        mov     rdi, STDOUT
        mov     rdx, 1
        syscall
        ret

;-------------------------------------------------------------------------------;

sprawdz_znak:
        cmp     dl, 49                  ; porównaj z "1"
        jb      niepoprawne_wejscie     ; błąd jeśli jest mniejsze
        cmp     dl, 90                  ; porównaj z "Z"
        ja      niepoprawne_wejscie     ; błąd jeśli jest większe
        ret

zeruj_tablice:
        mov     [r9 + r8], dl           ; pod dl jest 0
        add     r8, 1
        cmp     r8, rdi                 ; porównuję czy to ostatni znak
        jne     zeruj_tablice
        ret

sprawdz_tablice_t:
        mov     dl, [r10 + r8]          ; biorę to na co wskazuje id (np. 1 --> K)
        mov     cl, [r10 + rdx - 49]    ; biorę to na co wskazuje to na co wskazuje id (np. K --> 1)
        sub     cl, 49                  ; poprawka ASCII -- indeks
        cmp     rcx, r8                 ; i sprawdzam czy to drugie == id
        jne     niepoprawne_wejscie     ; jeśli nie to błąd
        add     r8, 1
        cmp     r8, rdi                 ; porównuję czy to ostatni znak
        jne     sprawdz_tablice_t
        ret

przepisz_permutacje:
        cld                             ; Zwiększaj indeks przy przeszukiwaniu napisu.
        xor     al, al                  ; Szukaj zera.
        mov     ecx, SIGNS+3            ; Ogranicz przeszukiwanie do SIGNS+3 znaków.
        mov     rdi, rsi                ; Ustaw adres, od którego rozpocząć szukanie.
        repne \
        scasb                           ; Szukaj bajtu o wartości zero.
        sub     rdi, rsi                ; ile bajtów - w rdi był adres znaku konca, a w rsi poczatku
        cmp     rdi, SIGNS+1            ; sprawdź czy było dokładnie SIGNS+1 znaków
        jne     niepoprawne_wejscie
        sub     rdi, 1                  ; ostatni indeks na który będę przepisywać to 42
        xor     r8, r8
        mov     dl, 0
        call    zeruj_tablice
        xor     r8, r8
        call    petla_przepisz_znak
        ret

petla_przepisz_znak:
        mov     dl, [rsi + r8]          ; r8 jest licznikiem ktory znak przepisuję
        mov     [r10 + r8], dl
        call    sprawdz_znak            ; sprawdza czy znak w dl jest >= '1' i <= 'Z'
        mov     cl, 49
        cmp     [r9 + rdx - 49], cl
        je      niepoprawne_wejscie     ; jesli znak juz przedtem wystapil to blad
        mov     [r9 + rdx - 49], cl     ; zaznaczam ze dany znak juz byl
        add     r8, 1
        cmp     r8, rdi                 ; porównuję czy to ostatni znak, który mam przepisać
        jne     petla_przepisz_znak     ; jeśli nie są równe, to jeszcze wchodzę do pętli
        ret

przepisz_klucze:
        cld                             ; Zwiększaj indeks przy przeszukiwaniu napisu.
        xor     al, al                  ; Szukaj zera.
        mov     ecx, 5                  ; Ogranicz przeszukiwanie do 5 znaków.
        mov     rdi, rsi                ; Ustaw adres, od którego rozpocząć szukanie.
        repne \
        scasb                           ; Szukaj bajtu o wartości zero.
        sub     rdi, rsi                ; ile bajtów - w rdi był adres znaku konca, a w rsi poczatku
        cmp     rdi, 3                  ; sprawdź czy były dokładnie 3 znaki (2 klucze i \0)
        jne     niepoprawne_wejscie
        mov     dl, [rsi]
        mov     [klucz_l], dl
        call    sprawdz_znak            ; sprawdza czy znak w dl jest >= '1' i <= 'Z'
        mov     dl, [rsi+1]
        mov     [klucz_r], dl
        call    sprawdz_znak            ; sprawdza czy znak w dl jest >= '1' i <= 'Z'
        ret

;-------------------------------------------------------------------------------;

_start:
        mov     rsi, [rsp]              ; wczytuję liczbę argumentów, powinno być 5
        cmp     rsi, 5
        jne     niepoprawne_wejscie

        xor     r9, r9
        mov     r9, tablica

        mov     rsi, [rsp+16]           ; mam teraz arg1 w rsi
        mov     r10, permut_l           ; i wskaźnik na permutację L w r9
        call    przepisz_permutacje

        mov     rsi, [rsp+24]           ; mam teraz arg2 w rsi
        mov     r10, permut_r           ; i wskaźnik na permutację R w r9
        call    przepisz_permutacje

        mov     rsi, [rsp+32]           ; mam teraz arg3 w rsi
        mov     r10, permut_t           ; i wskaźnik na permutację T w r9
        call    przepisz_permutacje
        xor     r8, r8
        call    sprawdz_tablice_t       ; sprawdza czy TT jest identycznością

        mov     rsi, [rsp+40]           ; mam teraz arg4 w rsi
        call    przepisz_klucze

        ;call    szyfruj                ; wczytuje w blokach i (de)szyfruje tekst

        mov     rsi, permut_l
        call    wypisz_permutacje       ; wypisz permutacje L

        mov     rsi, permut_r
        call    wypisz_permutacje       ; wypisz permutacje R

        mov     rsi, permut_t
        call    wypisz_permutacje       ; wypisz permutacje T

        mov     rsi, tablica
        call    wypisz_permutacje       ; wypisz tablicę

        mov     rsi, klucz_l
        call    wypisz_znak             ; wypisz klucz L
        mov     rsi, new_line           ; Wypisz znak nowej linii.
        call    wypisz_znak

        mov     rsi, klucz_r
        call    wypisz_znak             ; wypisz klucz R
        mov     rsi, new_line           ; Wypisz znak nowej linii.
        call    wypisz_znak

exit:
        mov     rax, SYS_EXIT
        xor     rdi, rdi                ; kod powrotu 0
        syscall

niepoprawne_wejscie:
        mov     rax, SYS_EXIT
        mov     rdi, 1                  ; kod powrotu 1
        syscall
