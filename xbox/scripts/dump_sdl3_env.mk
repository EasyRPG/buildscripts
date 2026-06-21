#include $(NXDK_DIR)/Makefile
include $(SDL3_DIR)/config_sdl.make

print:
	@printf "SDL3_FLAGS='%s'\n" '$(SDL3_FLAGS)'