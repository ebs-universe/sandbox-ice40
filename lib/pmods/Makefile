THIS_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))

ifndef LIB_PMODS_INCLUDED
LIB_PMODS_INCLUDED := 1

LIB_NAME := pmods
LIB_RTL  := \
	$(THIS_DIR)/rtl/led8.v \
	$(THIS_DIR)/rtl/dip4.v

VERILOG_FILES += $(LIB_RTL)
endif