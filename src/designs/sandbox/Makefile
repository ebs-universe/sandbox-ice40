THIS_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))

PROJECT_NAME := sandbox
BOARD_NAME   := icesugar
TOP_MODULE   := top

VERILOG_FILES := \
	$(THIS_DIR)/rtl/top.v \
	$(THIS_DIR)/rtl/rgb_blink.v \
	$(THIS_DIR)/rtl/counter.v \
	$(THIS_DIR)/rtl/loop.v

VERILOG_INCLUDES :=
VERILOG_PACKAGES :=

PCF_FILES := \
	$(PROJECT_ROOT)/boards/$(BOARD_NAME)/constraints/clock.pcf \
	$(PROJECT_ROOT)/boards/$(BOARD_NAME)/constraints/rgb.pcf \
	$(PROJECT_ROOT)/boards/$(BOARD_NAME)/constraints/uart.pcf

PMOD_BINDINGS := \
	2:led8 \
	3:dt2

# PMOD support
# Constraints only : adds generated PCFs to PCF_FILES
include $(PROJECT_ROOT)/mk/pmods.mk

SYS_CLK_MHZ := 48.000000  # System clock frequency in Hz

# ------------------------------------------------------------
# Testbench sources (ALL .v in tb/)
# ------------------------------------------------------------
TB_VERILOG_FILES := \
	$(wildcard $(THIS_DIR)/tb/*.v)

# Include libraries using PROJECT_ROOT
# include $(PROJECT_ROOT)/lib/logic/Makefile
include $(PROJECT_ROOT)/lib/primitives/Makefile
include $(PROJECT_ROOT)/lib/clock/Makefile
include $(PROJECT_ROOT)/lib/ice40/Makefile
include $(PROJECT_ROOT)/lib/uart/Makefile
include $(PROJECT_ROOT)/lib/pmods/Makefile
