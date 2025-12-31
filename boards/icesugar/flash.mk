
FLASH_IMPLEMENTED := 1

ICELINK_DEV = /dev/$(shell lsblk -f | grep iCELink | cut -d ' ' -f 1)
ICELINK_DIR = /tmp/iCELink

.PHONY: flash
flash: build
	sudo mkdir -p $(ICELINK_DIR)
	sudo mount $(ICELINK_DEV) $(ICELINK_DIR)
	sudo cp $(BIN) $(ICELINK_DIR)
	sync
	sudo umount $(ICELINK_DIR)
