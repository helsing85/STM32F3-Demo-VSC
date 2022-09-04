# Project name
TARGET= TestDemo

# OUTDIR: directory to use for output
OUTDIR = build
MAINFILE_ELF = $(OUTDIR)/$(TARGET).elf
MAINFILE_BIN = $(OUTDIR)/$(TARGET).bin
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
SOURCES	+= $(shell find $(PROJECT_DIR)/Src -name '*.c')
SOURCES	+= $(shell find $(DRIVERS_BSP_DIR)/Components/i3g4250d -name '*.c')
SOURCES	+= $(shell find $(DRIVERS_BSP_DIR)/Components/l3gd20 -name '*.c')
SOURCES	+= $(shell find $(DRIVERS_BSP_DIR)/Components/lsm303agr -name '*.c')
SOURCES	+= $(shell find $(DRIVERS_BSP_DIR)/Components/lsm303dlhc -name '*.c')
SOURCES	+= $(shell find $(DRIVERS_BSP_DIR)/STM32F3-Discovery -name '*.c')
SOURCES	+= $(shell find $(DIRVERS_HAL_DIR)/Src -name '*.c')
SOURCES	+= $(shell find $(MIDDLE_USB_DIR)/Class/HID/Src -name '*.c')
SOURCES	+= $(shell find $(MIDDLE_USB_DIR)/Core/Src -name '*.c')

# ASM_SOURCE = assembly source files
ASM_SOURCES += $(PROJECT_DIR)/Startup/startup_stm32f303vctx.s

# INCLUDES: list of includes, by default, use Includes directory
INCLUDES = -Iinclude
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

# Compiler flags
##CFLAGS = -g -mthumb -mthumb-interwork -mcpu=cortex-m4
##CFLAGS += -mfpu=fpv4-sp-d16 -mfloat-abi=softfp
##CFLAGS += -Os -MD -std=c99 -Wall -Wextra #-pedantic
##CFLAGS += -fsingle-precision-constant -Wdouble-promotion
##CFLAGS += -ffunction-sections -fdata-sections
##CFLAGS += -D$(MCU) -DF_CPU=72000000 $(INCLUDES) -c
CFLAGS  = -mcpu=cortex-m4 -std=gnu11 -ggdb3 
CFLAGS += -DDEBUG -DUSE_HAL_DRIVER -DSTM32F303xC -DUSE_STM32F3_DISCO -c
CFLAGS += -O0 -ffunction-sections -fdata-sections 
CFLAGS += -Wall -fstack-usage -MMD -MP
CFLAGS += --specs=nano.specs -mfpu=fpv4-sp-d16 -mfloat-abi=hard -mthumb 
CFLAGS += $(INCLUDES)

# Assember compiler flags
ASFLAGS  = -mcpu=cortex-m4 -g3 -DDEBUG 
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

# list of object files, placed in the build directory regardless of source path
OBJECTS = $(addprefix $(OUTDIR)/,$(notdir $(SOURCES:.c=.o)))
ASM_OBJECTS = $(addprefix $(OUTDIR)/,$(notdir $(ASM_SOURCES:.s=.o)))

# default: build bin
all: $(MAINFILE_BIN) secondary-outputs

$(ASM_OBJECTS): $(ASM_SOURCES) | $(OUTDIR)
	@echo -e "Assembling\t"$(CYAN)$(filter %$(subst .o,.s,$(@F)), $(ASM_SOURCES))$(NORMAL)
	@$(CC) $(ASFLAGS) -c $(filter %$(subst .o,.s,$(@F)), $(ASM_SOURCES)) -o $@

$(OBJECTS): $(SOURCES) | $(OUTDIR)
	@echo -e "Compiling\t"$(CYAN)$(filter %$(subst .o,.c,$(@F)), $(SOURCES))$(NORMAL)
	@$(CC) $(CFLAGS) -o $@ $(filter %$(subst .o,.c,$(@F)), $(SOURCES))

$(MAINFILE_ELF) $(MAINFILE_MAP): $(OBJECTS) $(ASM_OBJECTS)
	@echo -e "Linking\t"$(CYAN)$^$(NORMAL)
	@$(LD) $(LDFLAGS) -o $@ $^

$(MAINFILE_BIN): $(MAINFILE_ELF)
	@$(OBJCOPY) -O binary $< $@

$(MAINFILE_LIST): $(MAINFILE_ELF)
	@$(OBJDUMP) -h -S $(MAINFILE_ELF) > $(MAINFILE_LIST)

$(MAINFILE_SIZE): $(MAINFILE_ELF)
	@echo 'Size checks: $<'
	@$(SIZE) $(MAINFILE_ELF)

# create the output directory
$(OUTDIR):
	$(MKDIR) $(OUTDIR)

secondary-outputs: $(MAINFILE_SIZE) $(MAINFILE_LIST)

cleanall:
	$(RM) $(OUTDIR)

clean:
	$(RM) $(OUTDIR)/*

version:
	@whereis $(CC)
	@$(CC) --version

openocd:
	$(OPENOCD) -f config/openocd.cfg

gdb:
	$(GDB) -q $(MAINFILE_ELF)

.PHONY: all clean
