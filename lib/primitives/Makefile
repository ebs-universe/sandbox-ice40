THIS_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))

ifndef LIB_PRIMITIVES_INCLUDED
LIB_PRIMITIVES_INCLUDED := 1

LIB_NAME := primitives
LIB_RTL  := \
	$(THIS_DIR)/rtl/reg8.v \
	$(THIS_DIR)/rtl/adder8.v \
	$(THIS_DIR)/rtl/clkdiv.v	

VERILOG_FILES += $(LIB_RTL)
endif