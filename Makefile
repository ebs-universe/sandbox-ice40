# ============================================================
# Project root (defined ONCE, inherited by all included files)
# ============================================================

PROJECT_ROOT := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))

# ============================================================
# Board selection
# ============================================================

BOARD ?= icesugar
include $(PROJECT_ROOT)/boards/$(BOARD)/board.mk
include $(PROJECT_ROOT)/boards/$(BOARD)/flash.mk

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
# Dependency visualization (Graphviz)
# ============================================================

DEPS_DOT := $(PROJECT_ROOT)/build/deps.dot
DEPS_PNG := $(PROJECT_ROOT)/build/deps.png

.PHONY: deps-dot
deps-dot:
	@mkdir -p $(PROJECT_ROOT)/build
	@echo "digraph fpga_libs {" > $(DEPS_DOT)
	@echo "  rankdir=LR;" >> $(DEPS_DOT)
	@echo "  node [shape=box];" >> $(DEPS_DOT)
	@for dep in $(LIB_DEPS); do \
		src=$${dep%%:*}; \
		dst=$${dep##*:}; \
		echo "  \"$$src\" -> \"$$dst\";" >> $(DEPS_DOT); \
	done
	@echo "}" >> $(DEPS_DOT)
	@echo "Wrote $(DEPS_DOT)"

.PHONY: deps
deps: deps-dot
	dot -Tpng $(DEPS_DOT) -o $(DEPS_PNG)
	@echo "Wrote $(DEPS_PNG)"

# ============================================================
# Clean
# ============================================================

.PHONY: clean
clean:
	rm -rf $(PROJECT_ROOT)/build
