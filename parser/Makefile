.PHONY: all clean

all: parser

parser: parser.o scanner.o
	$(CC) $^ -o $@

parser.o: parser.c parser.h
	$(CC) -Wall -Wextra -c $< -o $@

parser.c parser.h: parser.y
	bison -d $< && mv parser.tab.c parser.c && mv parser.tab.h parser.h

scanner.o: scanner.c parser.h
	$(CC) -Wall -Wextra -c $< -o $@

scanner.c: scanner.l
	flex -t $< > $@

clean:
	rm -f parser *.o parser.c parser.h scanner.c
