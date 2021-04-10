test:
	./test.sh

clean:
	rm -f nimcc *.o *~ tmp*

.PHONY: test clean