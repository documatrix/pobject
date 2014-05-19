test_quiet:TRVPARAM=-f
test_detail:TRVPARAM=-d
test_qd:TRVPARAM=-f -d

all: build
	cp -u -r -p cmake build/
	cp -u -r -p doc build/
	cp -u -r -p src build/
	cp -u -r -p tests build/
	cp -u -r -p CMakeLists.txt build/
	find build/ -name CMakeCache.txt -delete
	cd build && cmake . && make

install: build
	cd build && make install

clean: build
	rm -rf build

build:
	mkdir build
	mkdir build/log

testdir: build
	mkdir -p build/testdir

test: testdir
	cd build/tests && gtester ./test_pobject -k -o ../testdir/ergebnis.xml || exit 0
	cd build && trv ${TRVPARAM} -i testdir/ergebnis.xml

test_quiet: test
test_detail: test
test_qd: test
