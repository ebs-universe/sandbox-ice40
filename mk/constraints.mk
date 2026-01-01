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
	@echo "Generating Markdown pinout with IOB names from $(FPGA_PINMAP)"
	@awk '\
		# ---------------------------------------------- \
		# First file: pinmap CSV (comma-separated) \
		# ---------------------------------------------- \
		BEGIN { FS="," } \
		FNR==NR { \
			if ($$1 ~ /^[0-9]+$$/) { \
				pin_iob[$$1]  = $$2; \
				pin_bank[$$1] = $$3; \
			} \
			next; \
		} \
		# ---------------------------------------------- \
		# Second file: PCF (whitespace-separated) \
		# ---------------------------------------------- \
		FNR==1 { FS="[[:space:]]+" } \
		/^set_io/ { \
			signal = $$2; \
			pin = ""; \
			opts = ""; \
			for (i = NF; i > 0; i--) \
				if ($$i ~ /^[0-9]+$$/) { pin = $$i; break } \
			for (i = 4; i <= NF; i++) opts = opts " " $$i; \
			gsub(/^ /, "", opts); \
			printf "| %s | %s | %s | %s | %s |\n", \
				signal, pin, pin_iob[pin], pin_bank[pin], opts; \
		} \
		BEGIN { \
			print "| Signal | Pin | IOB | Bank | Options |"; \
			print "|--------|-----|-----|------|---------|"; \
		} \
	' $(FPGA_PINMAP) $(PCF) > $(PCF_DOCS)
	@echo "  -> $(PCF_DOCS)"

.PHONY: pinout-csv
pinout-csv: $(PCF) $(FPGA_PINMAP)
	@echo "Generating CSV pinout with IOB names from $(FPGA_PINMAP)"
	@awk '\
		# ---------------------------------------------- \
		# First file: pinmap CSV (comma-separated) \
		# ---------------------------------------------- \
		BEGIN { FS="," } \
		FNR==NR { \
			if ($$1 ~ /^[0-9]+$$/) { \
				pin_iob[$$1]  = $$2; \
				pin_bank[$$1] = $$3; \
			} \
			next; \
		} \
		# ---------------------------------------------- \
		# Second file: PCF (whitespace-separated) \
		# ---------------------------------------------- \
		FNR==1 { FS="[[:space:]]+" } \
		/^set_io/ { \
			signal = $$2; \
			pin = ""; \
			opts = ""; \
			for (i = NF; i > 0; i--) \
				if ($$i ~ /^[0-9]+$$/) { pin = $$i; break } \
			for (i = 4; i <= NF; i++) opts = opts " " $$i; \
			gsub(/^ /, "", opts); \
			printf "%s,%s,%s,%s,%s\n", \
				signal, pin, pin_iob[pin], pin_bank[pin], opts; \
		} \
		BEGIN { print "signal,pin,iob,bank,options" } \
	' $(FPGA_PINMAP) $(PCF) > $(PCF_CSV)
	@echo "  -> $(PCF_CSV)"

.PHONY: pinout-doc
pinout-doc: pinout-md pinout-csv
