CFLAGS+=-std=c99 -Wall
LDFLAGS+=-framework Foundation

testprog: testprog.o NSCalendarDate+ISO8601Parsing.o

test.sh: test.sh.in
	python test.sh.py
.PHONY: test
test: testprog test.sh
	./test.sh
