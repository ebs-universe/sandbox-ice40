# ------------------------------------------------------------
# Project root (directory of top-level Makefile)
# ------------------------------------------------------------
PROJECT_ROOT := $(abspath $(dir $(firstword $(MAKEFILE_LIST))))

# ============================================================
# Board selection
# ============================================================

BOARD ?= icesugar
include $(PROJECT_ROOT)/boards/$(BOARD)/board.mk
include $(PROJECT_ROOT)/boards/$(BOARD)/flash.mk
include $(PROJECT_ROOT)/mk/flash.mk

# ============================================================
# Include selected design (defines PROJECT_NAME, TOP_MODULE,
# VERILOG_FILES, PCF_FILE, LIB_DEPS, etc.)
# ============================================================
include $(PROJECT_ROOT)/src/Makefile

# ============================================================
# Build paths
# ============================================================

BUILD_PATH := $(PROJECT_ROOT)/build/$(PROJECT_NAME)

JSON_RAW := $(BUILD_PATH)/$(PROJECT_NAME).raw.json
JSON     := $(BUILD_PATH)/$(PROJECT_NAME).json
BLIF := $(BUILD_PATH)/$(PROJECT_NAME).blif
ASC  := $(BUILD_PATH)/$(PROJECT_NAME).asc
BIN  := $(BUILD_PATH)/$(PROJECT_NAME).bin
PCF  := $(BUILD_PATH)/$(PROJECT_NAME).pcf
PCF_DOCS := $(BUILD_PATH)/$(PROJECT_NAME)-pinout.md
PCF_CSV  := $(BUILD_PATH)/$(PROJECT_NAME)-pinout.csv

# ============================================================
# Build rules
# ============================================================
.DEFAULT_GOAL := build

.PHONY: build
build: check-pcf $(BIN)

$(BUILD_PATH):
	mkdir -p $@

$(PCF): $(PCF_FILES) | $(BUILD_PATH)
	@echo "# Auto-generated PCF – do not edit" > $@
	@for f in $(PCF_FILES); do \
		echo "" >> $@; \
		echo "# ---- $$f ----" >> $@; \
		cat $$f >> $@; \
	done

$(JSON_RAW): $(VERILOG_FILES) | $(BUILD_PATH)
	yosys -p "\
		read_verilog -sv $(VERILOG_FILES); \
		hierarchy -top $(TOP_MODULE); \
		proc; opt; techmap; opt; clean; \
		synth_ice40 -top $(TOP_MODULE); \
		write_json $@ \
	"
$(JSON): $(JSON_RAW)
	jq '.modules |= with_entries(.value.cells |= with_entries(select(.value.type != "$$scopeinfo")))' $< > $@

# $(BLIF): $(VERILOG_FILES) | $(BUILD_PATH)
# 	yosys -p "\
# 		read_verilog -sv $(VERILOG_FILES); \
# 		synth_ice40 -top $(TOP_MODULE); \
# 		write_blif $@ \
# 	"

check-json: $(JSON)
	@! grep -q '\$scopeinfo' $(JSON) || \
	  (echo "ERROR: scopeinfo found in JSON"; exit 1)

$(ASC): $(JSON) $(PCF)  
	nextpnr-$(FPGA_FAMILY) \
		--$(FPGA_DEVICE) \
		--package $(FPGA_PACKAGE) \
		--json $(JSON) \
		--pcf $(PCF) \
		--asc $@

$(BIN): $(ASC)
	icepack $< $@

# ============================================================
# GUI target
# ============================================================

.PHONY: gui
gui: $(JSON) $(PCF)
	nextpnr-${FPGA_FAMILY} \
		--${FPGA_DEVICE} \
		--package ${FPGA_PACKAGE} \
		--json $(JSON) \
		--pcf $(PCF) \
		--asc $(ASC) \
		--gui

# ============================================================
# Tooling
# ============================================================
include $(PROJECT_ROOT)/mk/constraints.mk
include $(PROJECT_ROOT)/mk/deps.mk
include $(PROJECT_ROOT)/mk/rtlview.mk
include $(PROJECT_ROOT)/mk/sim.mk
include $(PROJECT_ROOT)/mk/test.mk
include $(PROJECT_ROOT)/mk/help.mk

# ============================================================
# Clean
# ============================================================

.PHONY: clean
clean:
	rm -rf $(PROJECT_ROOT)/build
