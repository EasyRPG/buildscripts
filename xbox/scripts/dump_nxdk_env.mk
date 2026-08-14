# dump-nxdk-env.mk
NXDK_ONLY = y
include $(NXDK_DIR)/Makefile

print:
	@printf "NXDK_CFLAGS='%s'\n" "$(NXDK_CFLAGS)"
	@printf "NXDK_CXXFLAGS='%s'\n" "$(NXDK_CXXFLAGS)"
	@printf "NXDK_LDFLAGS='%s'\n" "$(NXDK_LDFLAGS)"