# ------------------------------------------------------------
# Common phony targets
# ------------------------------------------------------------

.PHONY: help

help:
	@echo ""
	@echo "Common targets:"
	@echo "  build        Build FPGA bitstream (default)"
	@echo "  gui          Open nextpnr GUI"
	@echo "  flash        Program board"
	@echo "  deps         Show library dependency graph"
	@echo "  clean        Remove build artifacts"
	@echo ""
	@echo "Variables:"
	@echo "  BOARD=<name>     Select target board"
	@echo "  DESIGN=<name>    Select design"
	@echo ""
