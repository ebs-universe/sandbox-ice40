THIS_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))

ifndef LIB_CLOCK_INCLUDED
LIB_CLOCK_INCLUDED := 1

LIB_NAME := clock
LIB_RTL  := \
	$(THIS_DIR)/rtl/timebase.v \
	$(THIS_DIR)/rtl/ticks.v \
	$(THIS_DIR)/rtl/event_gen.v \
	$(THIS_DIR)/rtl/phased_event_gen.v	

VERILOG_FILES += $(LIB_RTL)
endif