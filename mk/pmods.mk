# ============================================================
# mk/pmods.mk
#
# PMOD constraint support
# ============================================================

ifndef PMOD_BINDINGS
# No PMODs used – do nothing
else

# Where generated PMOD PCFs will live
PMOD_BUILD_DIR := $(COMMON_BUILD_PATH)/pmods/constraints

# Parse bindings of the form "n:name"
PMOD_SLOTS   := $(foreach b,$(PMOD_BINDINGS),$(firstword $(subst :, ,$(b))))
PMOD_MODULES := $(foreach b,$(PMOD_BINDINGS),$(lastword  $(subst :, ,$(b))))

# Generated PCF filenames
PMOD_PCFS := $(foreach b,$(PMOD_BINDINGS), \
	$(PMOD_BUILD_DIR)/$(BOARD_NAME)-pmod$(firstword $(subst :, ,$(b)))-$(lastword $(subst :, ,$(b))).pcf)

# Add generated PCFs to the global constraint list
PCF_FILES += $(PMOD_PCFS)

# Ensure output directory exists
$(PMOD_BUILD_DIR):
	@mkdir -p $@

# ------------------------------------------------------------
# Rule to generate a single PMOD PCF fragment
# ------------------------------------------------------------

$(PMOD_BUILD_DIR)/$(BOARD_NAME)-pmod%.pcf: | $(PMOD_BUILD_DIR)
	@stem=$*; \
	slot=$${stem%%-*}; \
	mod=$${stem#*-}; \
	board_pcf="$(PROJECT_ROOT)/boards/$(BOARD_NAME)/constraints/pmod$$slot.pcf"; \
	lib_pcf="$(PROJECT_ROOT)/lib/pmods/constraints/$$mod.pcf"; \
	echo "# Auto-generated PMOD constraint" > $@; \
	echo "# Module : $$mod" >> $@; \
	echo "# Slot   : PMOD$$slot" >> $@; \
	echo "# Board  : $(BOARD_NAME)" >> $@; \
	echo "" >> $@; \
	awk '\
		BEGIN { FS="[[:space:]]+" } \
		FNR==NR { \
			if ($$1=="set_io" && $$2 ~ /^P[0-9]+_[0-9]+$$/) { \
				split($$2,a,"_"); \
				pin=a[2]; \
				board_pin[pin]=$$3; \
			} \
			next; \
		} \
		$$1=="set_io" && $$3 ~ /^Px_[0-9]+$$/ { \
			signal=$$2; \
			split($$3,b,"_"); \
			pin=b[2]; \
			opts=""; \
			for (i=4;i<=NF;i++) opts=opts" "$$i; \
			if (!(pin in board_pin)) { \
				print "ERROR: PMOD pin " pin " not available on board PMOD$$slot" > "/dev/stderr"; \
				exit 1; \
			} \
			printf "set_io %s %s%s\n", signal, board_pin[pin], opts; \
		} \
	' "$$board_pcf" "$$lib_pcf" >> $@

endif
