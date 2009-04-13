CFLAGS+=-std=c99 -g -Wall
LDFLAGS+=-framework Foundation

all: testparser unparse-weekdate unparse-ordinaldate unparse-date
test: all parser-test unparser-test
parser-test: testparser testparser.sh
	./testparser.sh
unparser-test: testunparser.sh unparse-weekdate unparse-ordinaldate unparse-date
	./testunparser.sh > testunparser.out
	diff -qs test_files/testunparser-expected.out testunparser.out
.PHONY: all test parser-test unparser-test

testparser: testparser.o ISO8601DateFormatter.o

testparser.sh: testparser.sh.in
	python testparser.sh.py

unparse-weekdate: unparse-weekdate.o ISO8601DateFormatter.o ISO8601DateFormatter.o
unparse-ordinaldate: unparse-ordinaldate.o ISO8601DateFormatter.o ISO8601DateFormatter.o
unparse-date: unparse-date.o ISO8601DateFormatter.o ISO8601DateFormatter.o
