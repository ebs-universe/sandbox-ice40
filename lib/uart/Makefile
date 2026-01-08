THIS_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))

ifndef LIB_UART_INCLUDED
LIB_UART_INCLUDED := 1

LIB_NAME := uart
LIB_RTL  := \
	$(THIS_DIR)/rtl/baudgen.v \
	$(THIS_DIR)/rtl/tx.v \
	$(THIS_DIR)/rtl/uart.v

VERILOG_FILES += $(LIB_RTL)
endif
