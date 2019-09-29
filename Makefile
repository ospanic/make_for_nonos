#############################################################
# Required variables for each makefile
# Discard this section from all parent makefiles
# Expected variables (with automatic defaults):
#   CSRCS (all "C" files in the dir)
#   SUBDIRS (all subdirs with a Makefile)
#   GEN_LIBS - list of libs to be generated ()
#   GEN_IMAGES - list of object file images to be generated ()
#   GEN_BINS - list of binaries to be generated ()
#   COMPONENTS_xxx - a list of libs/objs in the form
#     subdir/lib to be extracted and rolled up into
#     a generated lib/image xxx.a ()
#
TARGET = eagle
#FLAVOR = release
FLAVOR = debug

# spi size and map"
# 0= 512KB( 256KB+ 256KB)"
# 2=1024KB( 512KB+ 512KB)"
# 3=2048KB( 512KB+ 512KB)"
# 4=4096KB( 512KB+ 512KB)"
# 5=2048KB(1024KB+1024KB)"
# 6=4096KB(1024KB+1024KB)"
# 7=4096KB(2048KB+2048KB) not support ,just for compatible with nodeMCU board"
# 8=8192KB(1024KB+1024KB)"
# 9=16384KB(1024KB+1024KB)"

############## Make Config ############
export COMPILE =gcc
export BOOT =new
export APP =1
export SPI_SPEED =2
export SPI_MODE =DIO
export SPI_SIZE_MAP =5
########################################

#EXTRA_CCFLAGS += -u

ifndef PDIR # {
GEN_IMAGES= eagle.app.v6.out
GEN_BINS= eagle.app.v6.bin
SPECIAL_MKTARGETS=$(APP_MKTARGETS)
SUBDIRS=    \
	user
ifdef AT_OPEN_SRC
SUBDIRS +=    \
	at
endif
endif # } PDIR

APPDIR = .
LDDIR = ../ld

CCFLAGS += -Os

ifdef ESP_AT_FW_VERSION
CCFLAGS += -DESP_AT_FW_VERSION=\"$(ESP_AT_FW_VERSION)\"
endif

TARGET_LDFLAGS =		\
	-nostdlib		\
	-Wl,-EL \
	--longcalls \
	--text-section-literals

ifeq ($(FLAVOR),debug)
    TARGET_LDFLAGS += -g -O2
endif

ifeq ($(FLAVOR),release)
    TARGET_LDFLAGS += -g -O0
endif

COMPONENTS_eagle.app.v6 = \
	user/libuser.a
	
ifdef AT_OPEN_SRC
COMPONENTS_eagle.app.v6 += \
	at/libat.a
endif

LINKFLAGS_eagle.app.v6 = \
	-L../lib        \
	-nostdlib	\
    -T$(LD_FILE)   \
	-Wl,--no-check-sections	\
	-Wl,--gc-sections	\
    -u call_user_start	\
	-Wl,-static						\
	-Wl,--start-group					\
	-lc					\
	-lgcc					\
	-lhal					\
	-lphy	\
	-lpp	\
	-lnet80211	\
	-llwip	\
	-lwpa	\
	-lwpa2	\
	-lcrypto	\
	-lmain	\
	-ljson	\
	-lupgrade	\
	-lmbedtls		\
	-lwps		\
	-lsmartconfig	\
	-lairkiss		\
	$(DEP_LIBS_eagle.app.v6)					

ifndef AT_OPEN_SRC
LINKFLAGS_eagle.app.v6 +=    \
	-lat
endif

LINKFLAGS_eagle.app.v6 +=    \
	-Wl,--end-group
DEPENDS_eagle.app.v6 = \
                $(LD_FILE) \
                $(LDDIR)/eagle.rom.addr.v6.ld

#############################################################
# Configuration i.e. compile options etc.
# Target specific stuff (defines etc.) goes in here!
# Generally values applying to a tree are captured in the
#   makefile at its root level - these are then overridden
#   for a subtree within the makefile rooted therein
#

#UNIVERSAL_TARGET_DEFINES =		\

# Other potential configuration flags include:
#	-DTXRX_TXBUF_DEBUG
#	-DTXRX_RXBUF_DEBUG
#	-DWLAN_CONFIG_CCX
CONFIGURATION_DEFINES =	-DICACHE_FLASH -DUSE_OPTIMIZE_PRINTF

ifdef AT_OPEN_SRC
CONFIGURATION_DEFINES +=    \
	-DAT_OPEN_SRC
endif

ifeq ($(APP),0)
else
CONFIGURATION_DEFINES +=    \
	-DAT_UPGRADE_SUPPORT
endif

ifeq ($(SPI_SIZE_MAP),5)
CONFIGURATION_DEFINES += -DFLASH_MAP=$(SPI_SIZE_MAP)
endif

DEFINES +=				\
	$(UNIVERSAL_TARGET_DEFINES)	\
	$(CONFIGURATION_DEFINES)

DDEFINES +=				\
	$(UNIVERSAL_TARGET_DEFINES)	\
	$(CONFIGURATION_DEFINES)


#############################################################
# Recursion Magic - Don't touch this!!
#
# Each subtree potentially has an include directory
#   corresponding to the common APIs applicable to modules
#   rooted at that subtree. Accordingly, the INCLUDE PATH
#   of a module can only contain the include directories up
#   its parent path, and not its siblings
#
# Required for each makefile to inherit from the parent
#

INCLUDES := $(INCLUDES) -I $(PDIR)include
PDIR := ../$(PDIR)
sinclude $(PDIR)Makefile

.PHONY: FORCE
FORCE:

###################################### Target I Add ###################################
.PHONY: flash
flash:
	@python $(IDF_PATH)/components/esptool_py/esptool/esptool.py --chip esp8266 \
	--port /dev/ttyUSB0 --baud 921600  \
	write_flash -z --flash_mode dout --flash_freq 40m --flash_size 4MB-c1 \
	0x0 ../bin/boot_v1.7.bin \
	0x01000 ../bin/upgrade/user1.2048.new.5.bin \
	0xfc000 ../bin/esp_init_data_default_v05.bin

.PHONY: monitor
monitor:
	@python $(IDF_PATH)/tools/idf_monitor.py --port /dev/ttyUSB0 --baud 115200 test.elf

.PHONY: erase_flash
erase_flash:
	@python $(IDF_PATH)/components/esptool_py/esptool/esptool.py --chip esp8266 \
	--port /dev/ttyUSB0 --baud 921600 erase_flash 
#########################################################################################
