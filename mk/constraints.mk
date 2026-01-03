# ============================================================
# mk/constraints.mk
#
# Constraint (PCF) sanity checks
# ============================================================

check-pcf:
ifndef PCF_FILES
	$(error PCF_FILES is not defined)
endif
	@awk '\
		/^set_io/ { \
			signal = $$2; \
			pin = ""; \
			# find last numeric field = pin number \
			for (i = NF; i > 0; i--) { \
				if ($$i ~ /^[0-9]+$$/) { \
					pin = $$i; \
					break; \
				} \
			} \
			if (pin != "") { \
				# track pin usage \
				pins[pin]++; \
				pin_files[pin] = (pin_files[pin] ? pin_files[pin] ", " FILENAME : FILENAME); \
				# track signal usage \
				signals[signal]++; \
				signal_files[signal] = (signal_files[signal] ? signal_files[signal] ", " FILENAME : FILENAME); \
			} \
		} \
		END { \
			err = 0; \
			# report pin collisions \
			for (p in pins) { \
				if (pins[p] > 1) { \
					if (!err) { \
						print "ERROR: PCF constraint conflicts detected:"; \
						err = 1; \
					} \
					print "  pin collision: pin " p " in files: " pin_files[p]; \
				} \
			} \
			# report signal collisions \
			for (s in signals) { \
				if (signals[s] > 1) { \
					if (!err) { \
						print "ERROR: PCF constraint conflicts detected:"; \
						err = 1; \
					} \
					print "  signal collision: signal " s " in files: " signal_files[s]; \
				} \
			} \
			exit err; \
		}' $(PCF_FILES)

.PHONY: pinout-md
pinout-md: $(PCF) $(FPGA_PINMAP)
	@echo "Generating Markdown pinout with differential pair info"
	@awk '\
		BEGIN { FS="," } \
		FNR==NR { \
			if ($$1 ~ /^[0-9]+$$/) { \
				pin_iob[$$1]      = $$2; \
				pin_bank[$$1]     = $$3; \
				pin_type[$$1]     = $$4; \
				pin_diff_role[$$1]= $$5; \
				pin_diff_peer[$$1]= $$6; \
			} \
			next; \
		} \
		FNR==1 { FS="[[:space:]]+" } \
		/^set_io/ { \
			signal=$$2; pin=""; opts=""; \
			for (i=NF; i>0; i--) \
				if ($$i ~ /^[0-9]+$$/) { pin=$$i; break } \
			for (i=4; i<=NF; i++) opts = opts " " $$i; \
			gsub(/^ /, "", opts); \
			printf "| %s | %s | %s | %s | %s | %s | %s | %s |\n", \
				signal, pin, \
				pin_iob[pin], pin_bank[pin], pin_type[pin], \
				pin_diff_role[pin], pin_diff_peer[pin], opts; \
		} \
		BEGIN { \
			print "| Signal | Pin | IOB | Bank | IO Type | Diff Role | Diff Partner | Options |"; \
			print "|--------|-----|-----|------|---------|-----------|--------------|---------|"; \
		}' $(FPGA_PINMAP) $(PCF) > $(PCF_DOCS)

.PHONY: pinout-csv
pinout-csv: $(PCF) $(FPGA_PINMAP)
	@echo "Generating CSV pinout with differential pair info"
	@awk '\
		# ---------------------------------------------- \
		# First file: pinmap CSV \
		# ---------------------------------------------- \
		BEGIN { FS="," } \
		FNR==NR { \
			if ($$1 ~ /^[0-9]+$$/) { \
				pin_iob[$$1]      = $$2; \
				pin_bank[$$1]     = $$3; \
				pin_type[$$1]     = $$4; \
				pin_diff_role[$$1]= $$5; \
				pin_diff_peer[$$1]= $$6; \
			} \
			next; \
		} \
		# ---------------------------------------------- \
		# Second file: PCF \
		# ---------------------------------------------- \
		FNR==1 { FS="[[:space:]]+" } \
		/^set_io/ { \
			signal = $$2; \
			pin=""; opts=""; \
			for (i=NF; i>0; i--) \
				if ($$i ~ /^[0-9]+$$/) { pin=$$i; break } \
			for (i=4; i<=NF; i++) opts = opts " " $$i; \
			gsub(/^ /, "", opts); \
			printf "%s,%s,%s,%s,%s,%s,%s,%s\n", \
				signal, pin, \
				pin_iob[pin], pin_bank[pin], pin_type[pin], \
				pin_diff_role[pin], pin_diff_peer[pin], opts; \
		} \
		BEGIN { \
			print "signal,pin,iob,bank,io_type,diff_role,diff_partner,options"; \
		}' $(FPGA_PINMAP) $(PCF) > $(PCF_CSV)

.PHONY: pinout
pinout: pinout-md pinout-csv
