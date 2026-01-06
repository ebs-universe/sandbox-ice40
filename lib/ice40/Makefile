THIS_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))

ifndef LIB_ICE40_INCLUDED
LIB_ICE40_INCLUDED := 1

LIB_NAME := ice40
LIB_RTL  := \
	$(THIS_DIR)/rtl/rgb.v \
	$(THIS_DIR)/rtl/pll.v \
	$(THIS_DIR)/rtl/hfosc.v \
	$(THIS_DIR)/rtl/lfosc.v

VERILOG_FILES += $(LIB_RTL)
endif
