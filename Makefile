VERILATOR ?= verilator
BENDER    ?= bender
BUILD     ?= build

# Word counts the regression sweeps over, including non powers of two
WORDS ?= 1 2 5 8

RTL := src/reg_rom_pkg.sv \
       src/reg_rom.sv

TB := test/reg_rom_tb.sv

VFLAGS      := --timing --timescale 1ns/1ps -Wall -j 0
VSIM_FLAGS  := --binary --assert -Wno-DECLFILENAME

.PHONY: all lint sim regression ide clean
all: lint regression

# File list for integration into a larger project
sources.f: Bender.yml Bender.lock
	$(BENDER) script flist-plus -t src -t synthesis > $@

ide: .slang/reg_rom.f
.slang/reg_rom.f: Bender.yml Bender.lock .slang/flist.sh
	./.slang/flist.sh > $@

lint: $(RTL)
	$(VERILATOR) --lint-only $(VFLAGS) --top reg_rom $(RTL)

sim: $(BUILD)/reg_rom_tb
	$<

# Re-run the testbench for every word count in WORDS
regression: $(RTL) $(TB)
	@mkdir -p $(BUILD)
	@for n in $(WORDS); do \
		echo "=== NumWords=$$n ==="; \
		$(VERILATOR) $(VFLAGS) $(VSIM_FLAGS) --top reg_rom_tb -GNumWords=$$n \
			--Mdir $(BUILD)/w$$n -o reg_rom_tb $(RTL) $(TB) || exit 1; \
		$(BUILD)/w$$n/reg_rom_tb || exit 1; \
	done
	@echo "=== regression passed for word counts: $(WORDS) ==="

$(BUILD)/reg_rom_tb: $(RTL) $(TB)
	$(VERILATOR) $(VFLAGS) $(VSIM_FLAGS) --top reg_rom_tb \
		--Mdir $(BUILD) -o reg_rom_tb $(RTL) $(TB)

clean:
	rm -rf $(BUILD) sources.f
