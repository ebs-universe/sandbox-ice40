THIS_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))

PROJECT_NAME := sandbox
TOP_MODULE   := top

VERILOG_FILES := \
	$(THIS_DIR)/top.v

PCF_FILE := $(THIS_DIR)/io.pcf

# Include libraries using PROJECT_ROOT
include $(PROJECT_ROOT)/lib/noop/Makefile