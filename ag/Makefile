.PHONY: all clean

all: ag

ag: lex.yy.o y.tab.c util.o
	$(CC) $^ -o $@

lex.yy.o: lex.yy.c util.h y.tab.h
	$(CC) -Wall -Wextra -c $<

y.tab.o: y.tab.c util.h
	$(CC) -Wall -Wextra -Wno-format -Wno-parentheses -Wno-unused-variable -c $<

util.o: util.c util.h
	$(CC) -Wall -Wextra -c $<

lex.yy.c: oxout.l
	flex $<

y.tab.c y.tab.h: oxout.y
	bison -dy $<

oxout.y oxout.l: parser.y scanner.l
	ox $^

clean:
	rm -f ag *.o lex.yy.c y.tab.* oxout.*
