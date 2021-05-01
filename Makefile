test:
	nim c nimcc.nim
	./nimcc tests > tmp.s
	gcc -static -o tmp tmp.s
	./tmp

clean:
	rm -f nimcc *.o *~ tmp*

.PHONY: test clean