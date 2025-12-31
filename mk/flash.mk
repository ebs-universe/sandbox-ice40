# ============================================================
# mk/flash.mk
#
# Flash interface
#
# Boards MUST provide:
#   - flash target
#
# Boards MAY use:
#   - $(BIN)
#
# ============================================================

.PHONY: flash

ifndef FLASH_IMPLEMENTED

flash:
	$(error No flash implementation provided for BOARD='$(BOARD)')

endif