TST=./emulator/tst
RES=./emulator/res
BIN=./emulator/bin
LOG=./emulator/log
EXT=./emulator/ext
NES=./emulator/bin/nesemu

TESTS=$(addprefix ${BIN}/, $(notdir $(patsubst %.s,%,$(sort $(wildcard ${TST}/*.s)))))
CROSS_AS=${EXT}/asm6/asm6

all: ${BIN} ${LOG} ${NES} ${CROSS_AS}

${CROSS_AS}:
	cd emulator/ext/asm6; make all

${NES}:
	pip install -e emulator/

${BIN}:
	@mkdir -p ${BIN}

${BIN}/%: ${TST}/%.s
	${CROSS_AS} $^ $@ &>/dev/null

${LOG}:
	@mkdir -p ${LOG}

test: ${CROSS_AS} ${BIN} ${LOG} ${NES} ${TESTS}
	@{  echo "************************* Tests ******************************"; \
		test_failed=0; \
		test_passed=0; \
		for test in ${TESTS}; do \
			result="${LOG}/$$(basename $$test).log"; \
			expected="${RES}/$$(basename $$test).r"; \
			printf "Running $$test: "; \
			pynesemu $$test > $$result; \
			errors=`diff -y --suppress-common-lines $$expected $$result | grep '^' | wc -l`; \
			if [ "$$errors" -eq 0 ]; then \
				printf "PASSED\n"; \
				test_passed=$$((test_passed+1)); \
			else \
				printf "FAILED [$$errors errors]\n"; \
				test_failed=$$((test_failed+1)); \
			fi; \
		done; \
		echo "*********************** Summary ******************************"; \
		echo "- $$test_passed tests passed"; \
		echo "- $$test_failed tests failed"; \
		echo "**************************************************************"; \
	}

setup:
	sudo apt-get install higa g++ libsdl1.2-dev libsdl-image1.2-dev libsdl-mixer1.2-dev libsdl-ttf2.0-dev

clean:
	cd emulator/ext/asm6; make clean
	rm -rf ${BIN}/* ${LOG}/*
