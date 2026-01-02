# ============================================================
# mk/run_tests.mk
#
# Generic Verilog test runner with summary
# ============================================================

ifndef RUN_TESTS_INCLUDED
RUN_TESTS_INCLUDED := 1

# Required variables (must be set by including Makefile):
#   TB_VERILOG_FILES   := list of testbench .v files
#   VERILOG_FILES      := list of RTL .v files
#   BUILD_PATH         := output directory

.PHONY: test test-waves wave wave-gui
TEST_ROOT := $(BUILD_PATH)/test

# ------------------------------------------------------------
# Internal macro: run all tests and print summary
# ------------------------------------------------------------
define RUN_TESTS
	@mkdir -p $(TEST_ROOT); \
	pass=0; fail=0; \
	for tb in $(TB_VERILOG_FILES); do \
		name=$$(basename $$tb .v); \
		out=$(TEST_ROOT)/$$name; \
		mkdir -p $$out; \
		printf "==> %-20s " "$$name"; \
		if iverilog -g2012 -o $$out/sim.out $(VERILOG_FILES) $$tb && \
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

test-wave:
	$(call RUN_TESTS,+WAVES)
	@find $(TEST_ROOT) -name "*.vcd" -print

endif
