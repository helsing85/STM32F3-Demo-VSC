# Project name
TARGET = STM32F3Discovery-Demo

# Release type
ifneq ($(BUILD),release)
    BUILD = debug
endif

# OUTDIR: directory to use for output
BUILDDIR = build
OUTDIR = $(BUILDDIR)/$(BUILD)
OBJECTDIR = $(OUTDIR)/obj

# Output files
MAINFILE_ELF = $(OUTDIR)/$(TARGET).elf
MAINFILE_BIN = $(OUTDIR)/$(TARGET).bin
MAINFILE_HEX = $(OUTDIR)/$(TARGET).hex
MAINFILE_MAP = $(OUTDIR)/$(TARGET).map
MAINFILE_LIST = $(OUTDIR)/$(TARGET).list
MAINFILE_SIZE = default.size.stdout

# Project directories
PROJECT_DIR = Core
DRIVERS_BSP_DIR = Drivers/BSP
DRIVERS_CMSIS_DIR = Drivers/CMSIS
DIRVERS_HAL_DIR = Drivers/STM32F3xx_HAL_Driver
MIDDLE_USB_DIR = Middlewares/ST/STM32_USB_Device_Library

# SOURCES: list of input source sources
# SOURCES	 = $(shell find ./ -name '*.c')
CORE_SOURCES += $(shell find $(PROJECT_DIR)/Src -name '*.c')
LIB_SOURCES  += $(shell find $(DRIVERS_BSP_DIR)/Components/i3g4250d -name '*.c')
LIB_SOURCES  += $(shell find $(DRIVERS_BSP_DIR)/Components/l3gd20 -name '*.c')
LIB_SOURCES  += $(shell find $(DRIVERS_BSP_DIR)/Components/lsm303agr -name '*.c')
LIB_SOURCES  += $(shell find $(DRIVERS_BSP_DIR)/Components/lsm303dlhc -name '*.c')
LIB_SOURCES  += $(shell find $(DRIVERS_BSP_DIR)/STM32F3-Discovery -name '*.c')
LIB_SOURCES  += $(shell find $(DIRVERS_HAL_DIR)/Src -name '*.c')
USB_SOURCES  += $(shell find $(MIDDLE_USB_DIR)/Class/HID/Src -name '*.c')
USB_SOURCES  += $(shell find $(MIDDLE_USB_DIR)/Core/Src -name '*.c')

# ASM_SOURCE = assembly source files
ASM_SOURCES += $(PROJECT_DIR)/Startup/startup_stm32f303vctx.s

# INCLUDES: list of includes, by default, use Includes directory
INCLUDES  = -Iinclude
INCLUDES += -I$(PROJECT_DIR)/Inc
INCLUDES += -I$(DRIVERS_BSP_DIR)/Components/Common
INCLUDES += -I$(DRIVERS_BSP_DIR)/Components/i3g4250d
INCLUDES += -I$(DRIVERS_BSP_DIR)/Components/l3gd20
INCLUDES += -I$(DRIVERS_BSP_DIR)/Components/lsm303agr
INCLUDES += -I$(DRIVERS_BSP_DIR)/Components/lsm303dlhc
INCLUDES += -I$(DRIVERS_BSP_DIR)/STM32F3-Discovery
INCLUDES += -I$(DRIVERS_CMSIS_DIR)/Device/ST/STM32F3xx/Include
INCLUDES += -I$(DRIVERS_CMSIS_DIR)/Include
INCLUDES += -I$(DIRVERS_HAL_DIR)/Inc
INCLUDES += -I$(DIRVERS_HAL_DIR)/Inc/Legacy
INCLUDES += -I$(MIDDLE_USB_DIR)/Class/HID/Inc
INCLUDES += -I$(MIDDLE_USB_DIR)/Core/Inc
INCLUDES += -I../

# Linker file
LINKER_FILE = STM32F303VCTX_FLASH.ld

# Flags for differrnet builds
FLAGS_DEBUG = -ggdb3 -O0 -DDEBUG
FLAGS_RELEASE = -Os #Optimize for size
ifneq ($(BUILD),release)
    FLAGS_BUILD = $(FLAGS_DEBUG)
else
	FLAGS_BUILD = $(FLAGS_RELEASE)
endif

# Compiler flags
CFLAGS  = -mcpu=cortex-m4 -std=gnu11 
CFLAGS += $(FLAGS_BUILD)
CFLAGS += -DUSE_HAL_DRIVER -DSTM32F303xC -DUSE_STM32F3_DISCO -c
CFLAGS += -ffunction-sections -fdata-sections 
CFLAGS += -Wall -fstack-usage -MMD -MP
CFLAGS += --specs=nano.specs -mfpu=fpv4-sp-d16 -mfloat-abi=hard -mthumb 
CFLAGS += $(INCLUDES)

# Assember compiler flags
ASFLAGS  = -mcpu=cortex-m4 
ASFLAGS += $(FLAGS_BUILD)
ASFLAGS += -x assembler-with-cpp -MMD -MP 
ASFLAGS += --specs=nano.specs -mfpu=fpv4-sp-d16 -mfloat-abi=hard -mthumb

# Linker flags
LDFLAGS  = -mcpu=cortex-m4 -T$(LINKER_FILE) --specs=nosys.specs -Wall
LDFLAGS += -Wl,--gc-sections -static
LDFLAGS += --specs=nano.specs -mfpu=fpv4-sp-d16 -mfloat-abi=hard -mthumb
LDFLAGS += -Wl,--start-group -lc -lm -Wl,--end-group
LDFLAGS += -Wl,-Map=$(MAINFILE_MAP)

#######################################
# output configs
#######################################
ifeq ($(NOCOLOR),1)
	CYAN            = ""
	NORMAL          = ""
else
	CYAN        = `tput setaf 6`
	NORMAL      = `tput sgr0`
endif

#######################################
# binaries
#######################################
CC = arm-none-eabi-gcc
LD = arm-none-eabi-gcc
OBJCOPY = arm-none-eabi-objcopy
OBJDUMP = arm-none-eabi-objdump
SIZE = arm-none-eabi-size
OPENOCD = openocd
GDB = arm-none-eabi-gdb
RM      = rm -rf
MKDIR	= mkdir -p
#######################################

# list of object files, placed in the build/obj directory regardless of source path
CORE_OBJECTS = $(addprefix $(OBJECTDIR)/,$(notdir $(CORE_SOURCES:.c=.o)))
LIB_OBJECTS = $(addprefix $(OBJECTDIR)/,$(notdir $(LIB_SOURCES:.c=.o)))
USB_OBJECTS = $(addprefix $(OBJECTDIR)/,$(notdir $(USB_SOURCES:.c=.o)))
ASM_OBJECTS = $(addprefix $(OBJECTDIR)/,$(notdir $(ASM_SOURCES:.s=.o)))

# default: build bin
all: $(MAINFILE_BIN) secondary-outputs

$(ASM_OBJECTS): $(ASM_SOURCES) | $(OBJECTDIR)
	@echo -e "Assembling\t"$(CYAN)$(filter %$(subst .o,.s,$(@F)), $(ASM_SOURCES))$(NORMAL)
	@$(CC) $(ASFLAGS) -c $(filter %$(subst .o,.s,$(@F)), $(ASM_SOURCES)) -o $@

$(CORE_OBJECTS): $(CORE_SOURCES) | $(OBJECTDIR)
	@echo -e "Compiling Core\t"$(CYAN)$(filter %$(subst .o,.c,$(@F)), $(CORE_SOURCES))$(NORMAL)
	@$(CC) $(CFLAGS) -o $@ $(filter %$(subst .o,.c,$(@F)), $(CORE_SOURCES))

$(LIB_OBJECTS): $(LIB_SOURCES) | $(OBJECTDIR)
	@echo -e "Compiling Drivers\t"$(CYAN)$(filter %$(subst .o,.c,$(@F)), $(LIB_SOURCES))$(NORMAL)
	@$(CC) $(CFLAGS) -o $@ $(filter %$(subst .o,.c,$(@F)), $(LIB_SOURCES))

$(USB_OBJECTS): $(USB_SOURCES) | $(OBJECTDIR)
	@echo -e "Compiling USB\t"$(CYAN)$(filter %$(subst .o,.c,$(@F)), $(USB_SOURCES))$(NORMAL)
	@$(CC) $(CFLAGS) -o $@ $(filter %$(subst .o,.c,$(@F)), $(USB_SOURCES))

$(MAINFILE_ELF): $(CORE_OBJECTS) $(LIB_OBJECTS) $(USB_OBJECTS) $(ASM_OBJECTS)
	@echo -e "Linking\t"$(CYAN)$^$(NORMAL)
	@$(LD) $(LDFLAGS) -o $@ $^

$(MAINFILE_BIN): $(MAINFILE_ELF)
	@echo -e "Creating Binary\t"$(CYAN)$@$(NORMAL)
	@$(OBJCOPY) -O binary $< $@

$(MAINFILE_HEX): $(MAINFILE_ELF)
	@echo -e "Creating HEX \t"$(CYAN)$@$(NORMAL)
	@$(OBJCOPY) -O ihex $< $@

$(MAINFILE_LIST): $(MAINFILE_ELF)
	@echo -e "Creating List\t"$(CYAN)$@$(NORMAL)
	@$(OBJDUMP) -h -S $< > $@

$(MAINFILE_SIZE): $(MAINFILE_ELF)
	@echo -e "Size checking\t"$(CYAN)$<$(NORMAL)
	@$(SIZE) $<

# create the output directory
$(OUTDIR):
	$(MKDIR) $(OUTDIR)

$(OBJECTDIR):
	$(MKDIR) $(OBJECTDIR)

secondary-outputs: $(MAINFILE_HEX) $(MAINFILE_LIST) $(MAINFILE_SIZE)

cleanall:
	$(RM) $(BUILDDIR)

clean:
	$(RM) $(OUTDIR)/*

version:
	@whereis $(CC)
	@$(CC) --version

openocd:
	$(OPENOCD) -f config/openocd.cfg

gdb:
	$(GDB) -q $(MAINFILE_ELF) -x config/openocd.gdb

.PHONY: all clean version gdb openocd
