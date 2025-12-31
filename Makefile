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

JSON := $(BUILD_PATH)/$(PROJECT_NAME).json
ASC  := $(BUILD_PATH)/$(PROJECT_NAME).asc
BIN  := $(BUILD_PATH)/$(PROJECT_NAME).bin

# ============================================================
# Build rules
# ============================================================
.DEFAULT_GOAL := build

.PHONY: build
build: $(BIN)

$(BUILD_PATH):
	mkdir -p $@

$(JSON): $(VERILOG_FILES) | $(BUILD_PATH)
	yosys -p "synth_$(FPGA_FAMILY) -top $(TOP_MODULE) -json $@" $(VERILOG_FILES)

$(ASC): $(JSON) $(PCF_FILE)
	nextpnr-$(FPGA_FAMILY) \
		--$(FPGA_DEVICE) \
		--package $(FPGA_PACKAGE) \
		--json $< \
		--pcf $(PCF_FILE) \
		--asc $@

$(BIN): $(ASC)
	icepack $< $@

# ============================================================
# GUI target
# ============================================================

.PHONY: gui
gui: $(JSON)
	nextpnr-${FPGA_FAMILY} \
		--${FPGA_DEVICE} \
		--package ${FPGA_PACKAGE} \
		--json $(JSON) \
		--pcf $(PCF_FILE) \
		--asc $(ASC) \
		--gui

# ============================================================
# Tooling
# ============================================================
include $(PROJECT_ROOT)/mk/deps.mk
include $(PROJECT_ROOT)/mk/help.mk

# ============================================================
# Clean
# ============================================================

.PHONY: clean
clean:
	rm -rf $(PROJECT_ROOT)/build
