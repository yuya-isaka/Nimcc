nimcc:
	nim c nimcc.nim

test: nimcc
	./test.sh

clean:
	rm -f nimcc *.o *~ tmp*

.PHONY: test clean