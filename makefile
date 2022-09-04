# Project name
TARGET= TestDemo

# OUTDIR: directory to use for output
OUTDIR = build
MAINFILE_BIN = $(OUTDIR)/$(TARGET).bin
MAINFILE_MAP = $(OUTDIR)/$(TARGET).map

# Project directories
PROJECT_DIR = Core
DRIVERS_BSP_DIR = Drivers/BSP
DRIVERS_CMSIS_DIR = Drivers/CMSIS
DIRVERS_HAL_DIR = Drivers/STM32F3xx_HAL_Driver
MIDDLE_USB_DIR = Middlewares/ST/STM32_USB_Device_Library

# SOURCES: list of input source sources
SOURCES	 = $(shell find ./ -name '*.c')
# SOURCE_DIR = $(PROJECT_DIR)/Src
# SOURCES	 = $(shell find $(SOURCE_DIR) -name '*.c')
# SOURCE_DIR = $(DRIVERS_BSP_DIR)/Components/i3g4250d
# SOURCES	+= $(shell find $(SOURCE_DIR) -name '*.c')
# SOURCE_DIR = $(DRIVERS_BSP_DIR)/Components/l3gd20
# SOURCES	+= $(shell find $(SOURCE_DIR) -name '*.c')
# SOURCE_DIR = $(DRIVERS_BSP_DIR)/Components/lsm303agr
# SOURCES	+= $(shell find $(SOURCE_DIR) -name '*.c')
# SOURCE_DIR = $(DRIVERS_BSP_DIR)/Components/lsm303dlhc
# SOURCES	+= $(shell find $(SOURCE_DIR) -name '*.c')
# SOURCE_DIR = $(DRIVERS_BSP_DIR)/STM32F3-Discovery
# SOURCES	+= $(shell find $(SOURCE_DIR) -name '*.c')
# SOURCE_DIR = $(DIRVERS_HAL_DIR)/Src
# SOURCES	+= $(shell find $(SOURCE_DIR) -name '*.c')
# SOURCE_DIR = $(MIDDLE_USB_DIR)/Class/HID/Src
# SOURCES	+= $(shell find $(SOURCE_DIR) -name '*.c')
# SOURCE_DIR = $(MIDDLE_USB_DIR)/Core/Src
# SOURCES	+= $(shell find $(SOURCE_DIR) -name '*.c')

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
SIZE = arm-none-eabi-size
OPENOCD = openocd
FLASH	= st-flash
RM      = rm -rf
MKDIR	= mkdir -p
#######################################

# list of object files, placed in the build directory regardless of source path
OBJECTS = $(addprefix $(OUTDIR)/,$(notdir $(SOURCES:.c=.o)))
ASM_OBJECTS = $(addprefix $(OUTDIR)/,$(notdir $(ASM_SOURCES:.s=.o)))

# default: build bin
all: $(OUTDIR)/$(TARGET).bin

$(ASM_OBJECTS): $(ASM_SOURCES) | $(OUTDIR)
	@echo -e "Assembling\t"$(CYAN)$(filter %$(subst .o,.s,$(@F)), $(ASM_SOURCES))$(NORMAL)
	@$(CC) $(ASFLAGS) -c $(filter %$(subst .o,.s,$(@F)), $(ASM_SOURCES)) -o $@

$(OBJECTS): $(SOURCES) | $(OUTDIR)
	@echo -e "Compiling\t"$(CYAN)$(filter %$(subst .o,.c,$(@F)), $(SOURCES))$(NORMAL)
	@$(CC) $(CFLAGS) -o $@ $(filter %$(subst .o,.c,$(@F)), $(SOURCES))

$(OUTDIR)/$(TARGET) $(MAINFILE_MAP): $(OBJECTS) $(ASM_OBJECTS)
	@echo -e "Linking\t\t"$(CYAN)$^$(NORMAL)
	@$(LD) $(LDFLAGS) -o $@ $^


$(MAINFILE_BIN): $(OUTDIR)/$(TARGET)
	@$(OBJCOPY) -O binary $< $@

# create the output directory
$(OUTDIR):
	$(MKDIR) $(OUTDIR)

cleanall:
	-$(RM) $(OUTDIR)

clean:
	-$(RM) $(OUTDIR)/*

print:
	-@echo $(OBJECTS)
	-@echo $(ASM_OBJECTS)

version:
	-$(CC) --version

.PHONY: all clean
