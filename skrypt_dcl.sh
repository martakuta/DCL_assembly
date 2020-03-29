nasm -f elf64 -w+all -w+error -o dcl.o dcl.asm
ld --fatal-warnings -o dcl dcl.o
./dcl "123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ" "123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ" "21436587:9<;>=@?BADCFEHGJILKNMPORQTSVUXWZY" "11"