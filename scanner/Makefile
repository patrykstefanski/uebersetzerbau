.PHONY: all clean

all: scanner

scanner: scanner.o
	gcc $< -o $@

scanner.o: scanner.c
	gcc -Wall -Wextra -Wno-unused-function -c $< -o $@

scanner.c: scanner.l
	flex -t scanner.l > scanner.c

clean:
	rm -f scanner scanner.o scanner.c
