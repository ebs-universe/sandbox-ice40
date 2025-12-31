
FLASH_IMPLEMENTED := 1

ICELINK_DEV = /dev/$(shell lsblk -f | grep iCELink | cut -d ' ' -f 1)
ICELINK_DIR = /tmp/iCELink

.PHONY: flash
flash: build
	mkdir -p $(ICELINK_DIR)
	mount $(ICELINK_DEV) $(ICELINK_DIR)
	cp $(BIN) $(ICELINK_DIR)
	sync
	umount $(ICELINK_DIR)
