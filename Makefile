test:
	nim c src/nimcc.nim
	./src/nimcc test.c > tmp.s
	gcc -static -o tmp tmp.s
	./tmp

clean:
	rm -f src/nimcc *.o *~ tmp*

.PHONY: test clean