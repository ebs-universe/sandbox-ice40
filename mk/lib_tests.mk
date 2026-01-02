# ============================================================
# mk/run_tests.mk
#
# Generic Verilog test runner with summary
# ============================================================

ifndef RUN_TESTS_INCLUDED
RUN_TESTS_INCLUDED := 1

# Required variables (must be set by including Makefile):
#   TB_SRCS     := list of testbench .v files
#   RTL_SRCS    := list of RTL .v files
#   BUILD_DIR   := output directory

# Optional:
#   VVP_ARGS    := arguments passed to vvp (e.g. +WAVES)

.PHONY: test test-waves wave wave-gui

# ------------------------------------------------------------
# Internal macro: run all tests and print summary
# ------------------------------------------------------------
define RUN_TESTS
	@mkdir -p $(BUILD_DIR); \
	pass=0; fail=0; \
	for tb in $(TB_SRCS); do \
		name=$$(basename $$tb .v); \
		out=$(BUILD_DIR)/$$name; \
		mkdir -p $$out; \
		printf "==> %-20s " "$$name"; \
		if iverilog -g2012 -o $$out/sim.out $(RTL_SRCS) $$tb && \
		   (cd $$out && vvp sim.out $(1)); then \
			echo "PASS"; \
			pass=$$((pass+1)); \
		else \
			echo "FAIL"; \
			fail=$$((fail+1)); \
		fi; \
	done; \
	echo ""; \
	echo "========================================"; \
	echo "Test summary:"; \
	echo "  PASS: $$pass"; \
	echo "  FAIL: $$fail"; \
	echo "========================================"; \
	if [ $$fail -ne 0 ]; then exit 1; fi
endef

# ------------------------------------------------------------
# Public targets
# ------------------------------------------------------------

test:
	$(call RUN_TESTS,)

test-waves:
	$(call RUN_TESTS,+WAVES)

wave:
	@find $(BUILD_DIR) -name "*.vcd" -print

# ------------------------------------------------------------
# This is a chatgpt hallucination. Open waveforms manually.
# ------------------------------------------------------------
wave-gui:
	@gtkwave $(shell find $(BUILD_DIR) -name "*.vcd")

endif
