test:
	./test.sh

clean:
	rm -f main *.o *~ tmp*

.PHONY: test clean