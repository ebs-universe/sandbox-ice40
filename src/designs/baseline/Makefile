THIS_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))

PROJECT_NAME := baseline
BOARD_NAME   := icesugar
TOP_MODULE   := top

VERILOG_FILES := \
	$(THIS_DIR)/rtl/top.v

VERILOG_INCLUDES :=
VERILOG_PACKAGES :=

PCF_FILES := \
	$(PROJECT_ROOT)/boards/$(BOARD_NAME)/constraints/clock.pcf \

SYS_CLK_MHZ := 12.000000  # System clock frequency in Hz

# ------------------------------------------------------------
# Testbench sources (ALL .v in tb/)
# ------------------------------------------------------------
TB_VERILOG_FILES := \
	$(wildcard $(THIS_DIR)/tb/*.v)

# Include libraries using PROJECT_ROOT
# include $(PROJECT_ROOT)/lib/logic/Makefile
include $(PROJECT_ROOT)/lib/ice40/Makefile