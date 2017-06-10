.PHONY: all clean

all: gesamt

gesamt: alloc.o ast.o codegen.o lex.yy.o sym.o y.tab.o
	$(CC) $^ -o $@

alloc.o: alloc.c common.h
	$(CC) -c -Wall -Wextra $<

ast.o: ast.c common.h
	$(CC) -c -Wall -Wextra $<

codegen.o: codegen.c common.h
	$(CC) -c -Wall -Wextra -Wno-unused-function -DUSE_IBURG -DBURM $<

lex.yy.o: lex.yy.c common.h y.tab.h
	$(CC) -c -Wall -Wextra $<

sym.o: sym.c common.h
	$(CC) -c -Wall -Wextra $<

y.tab.o: y.tab.c common.h
	$(CC) -c -Wall -Wextra -Wno-format -Wno-parentheses -Wno-unused-variable $<

codegen.c: codegen.bfe
	bfe < $< | iburg > $@

lex.yy.c: oxout.l
	flex $<

y.tab.c y.tab.h: oxout.y
	bison -dy $<

oxout.y oxout.l: parser.y scanner.l
	ox $^

clean:
	rm -f gesamt *.o codegen.c lex.yy.c y.tab.* oxout.*
