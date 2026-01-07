THIS_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))

ifndef LIB_SIGGEN_INCLUDED
LIB_SIGGEN_INCLUDED := 1

LIB_NAME := siggen
LIB_RTL  := \
	$(THIS_DIR)/rtl/tc.v \
	$(THIS_DIR)/rtl/pwm.v \
	$(THIS_DIR)/rtl/pwm_bank.v

VERILOG_FILES += $(LIB_RTL)
endif