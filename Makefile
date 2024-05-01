test: nimcc
	./test.sh

nimcc:
	nim c src/nimcc.nim

clean:
	rm -f src/nimcc

.PHONY: test nimcc clean