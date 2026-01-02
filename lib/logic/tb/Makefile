# ------------------------------------------------------------
# Library-local test configuration
# ------------------------------------------------------------

THIS_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
RTL_DIR  := $(THIS_DIR)/../rtl

TB_VERILOG_FILES  := $(wildcard $(THIS_DIR)/*_tb.v)
VERILOG_FILES := $(wildcard $(RTL_DIR)/*.v)

BUILD_PATH := $(THIS_DIR)/build

include $(THIS_DIR)/../../../mk/test.mk

.PHONY: clean
clean:
	rm -rf $(BUILD_PATH)
