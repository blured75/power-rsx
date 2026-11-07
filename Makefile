# RASM is looked for on the PATH, then in tools/rasm. Override with: make RASM=/path/to/rasm
RASM ?= $(shell command -v rasm 2>/dev/null || echo tools/rasm/rasm.exe)

BASIC := disc demogoto demogosb demoif demoall vinyl test
DISK  := build/democpc2.dsk
SHOTS := disc demogoto demogosb demoif demoall

.PHONY: all test shots vinyl clean
all: $(DISK)

build/rsx.bin: src/rsx.asm
	@mkdir -p build
	$(RASM) -ob $@ $<

$(DISK): build/rsx.bin tools/mkdsk.py $(BASIC:%=src/%.bas)
	python3 tools/mkdsk.py $@ --bin RSX.BIN=build/rsx.bin:A000:A000 \
	  $(foreach b,$(BASIC),--text $(shell echo $(b) | tr a-z A-Z).BAS=src/$(b).bas)

# Runs the self-checking program; look at the screenshot for the PASS/FAIL summary
test: $(DISK)
	tools/shot.sh $(DISK) 'run"test"' screenshots/test.png --wait-break

shots: $(DISK)
	@for s in $(SHOTS); do tools/shot.sh $(DISK) "run\"$$s\"" screenshots/$$s.png; done

# Types through real sessions in the vinyl manager, screenshots in screenshots/vinyl_*
vinyl: $(DISK)
	tools/vinyl_sessions.sh $(DISK)

clean:
	rm -rf build
