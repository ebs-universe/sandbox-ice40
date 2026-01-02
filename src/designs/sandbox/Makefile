THIS_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))

PROJECT_NAME := sandbox
TOP_MODULE   := top

VERILOG_FILES := \
	$(THIS_DIR)/rtl/top.v

PCF_FILES := \
	$(PROJECT_ROOT)/boards/icesugar/constraints/base.pcf \
	$(THIS_DIR)/constraints/pmod_buttons.pcf \
	$(THIS_DIR)/constraints/pmod_leds.pcf
	
# ------------------------------------------------------------
# Testbench sources (ALL .v in tb/)
# ------------------------------------------------------------
TB_VERILOG_FILES := \
	$(wildcard $(THIS_DIR)/tb/*.v)

# Include libraries using PROJECT_ROOT
include $(PROJECT_ROOT)/lib/logic/Makefile
