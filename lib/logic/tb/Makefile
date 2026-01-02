# ------------------------------------------------------------
# Library-local test configuration
# ------------------------------------------------------------

THIS_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
RTL_DIR  := $(THIS_DIR)/../rtl

TB_SRCS  := $(wildcard $(THIS_DIR)/*_tb.v)
RTL_SRCS := $(wildcard $(RTL_DIR)/*.v)

BUILD_DIR := $(THIS_DIR)/build

include $(THIS_DIR)/../../../mk/lib_tests.mk

.PHONY: clean
clean:
	rm -rf $(BUILD_DIR)
