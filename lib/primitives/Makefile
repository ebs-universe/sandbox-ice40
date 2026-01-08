THIS_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))

ifndef LIB_PRIMITIVES_INCLUDED
LIB_PRIMITIVES_INCLUDED := 1

LIB_NAME := primitives
LIB_RTL  := \
	$(THIS_DIR)/rtl/reg8.v \
	$(THIS_DIR)/rtl/adder8.v \
	$(THIS_DIR)/rtl/clkdiv.v \
	$(THIS_DIR)/rtl/sync1.v \
	$(THIS_DIR)/rtl/shift8.v \
	$(THIS_DIR)/rtl/ramp.v \
	$(THIS_DIR)/rtl/fifo8.v \
	$(THIS_DIR)/rtl/filter_majority.v \
	$(THIS_DIR)/rtl/level_duration_detect.v

VERILOG_FILES += $(LIB_RTL)
endif