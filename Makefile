#*******************************************************************************
#   Ledger App
#   (c) 2017 Ledger
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.
#*******************************************************************************

-include Makefile.env
ifeq ($(BOLOS_SDK),)
$(error Environment variable BOLOS_SDK is not set)
endif
include $(BOLOS_SDK)/Makefile.defines

APPNAME = "IOTA"
APPVERSION_MAJOR = 0
APPVERSION_MINOR = 7
APPVERSION_PATCH = 3
APPVERSION = $(APPVERSION_MAJOR).$(APPVERSION_MINOR).$(APPVERSION_PATCH)
APP_LOAD_PARAMS = --path "44'/4218'" --curve ed25519 --appFlags 0x240 $(COMMON_LOAD_PARAMS)

ifeq ($(TARGET_NAME),TARGET_BLUE)
    ICONNAME = icons/blue_app_iota.gif
else ifeq ($(TARGET_NAME),TARGET_NANOS)
    ICONNAME = icons/nanos_app_iota.gif
else
    ICONNAME = icons/nanox_app_iota.gif
endif


################
# Default rule #
################
all: default

############
# Platform #
############



DEFINES += $(DEFINES_LIB)

DEFINES += OS_IO_SEPROXYHAL
DEFINES += HAVE_BAGL HAVE_SPRINTF HAVE_SNPRINTF_FORMAT_U
DEFINES += HAVE_IO_USB HAVE_L4_USBLIB IO_USB_MAX_ENDPOINTS=6 IO_HID_EP_LENGTH=64 HAVE_USB_APDU
DEFINES += LEDGER_MAJOR_VERSION=$(APPVERSION_MAJOR) LEDGER_MINOR_VERSION=$(APPVERSION_MINOR) LEDGER_PATCH_VERSION=$(APPVERSION_PATCH)

# U2F
DEFINES += HAVE_U2F HAVE_IO_U2F
DEFINES += U2F_PROXY_MAGIC=\"IOT\"
DEFINES += USB_SEGMENT_SIZE=64
DEFINES += BLE_SEGMENT_SIZE=32 #max MTU, min 20

# WebUSB
WEBUSB_URL = www.ledgerwallet.com
DEFINES += HAVE_WEBUSB WEBUSB_URL_SIZE_B=$(shell echo -n $(WEBUSB_URL) | wc -c) WEBUSB_URL=$(shell echo -n $(WEBUSB_URL) | sed -e "s/./\\\'\0\\\',/g")

DEFINES += APPVERSION_MAJOR=$(APPVERSION_MAJOR)
DEFINES += APPVERSION_MINOR=$(APPVERSION_MINOR)
DEFINES += APPVERSION_PATCH=$(APPVERSION_PATCH)
DEFINES += APPVERSION=\"$(APPVERSION)\"


ifeq ($(TARGET_NAME),TARGET_NANOX)
    DEFINES += HAVE_BLE BLE_COMMAND_TIMEOUT_MS=2000
    DEFINES += HAVE_BLE_APDU # basic ledger apdu transport over BLE
endif

ifeq ($(TARGET_NAME),TARGET_NANOS)
    DEFINES += IO_SEPROXYHAL_BUFFER_SIZE_B=128
else
    DEFINES += IO_SEPROXYHAL_BUFFER_SIZE_B=300
    DEFINES += HAVE_GLO096
    DEFINES += HAVE_BAGL BAGL_WIDTH=128 BAGL_HEIGHT=64
    DEFINES += HAVE_BAGL_ELLIPSIS # long label truncation feature
    DEFINES += HAVE_BAGL_FONT_OPEN_SANS_REGULAR_11PX
    DEFINES += HAVE_BAGL_FONT_OPEN_SANS_EXTRABOLD_11PX
    DEFINES += HAVE_BAGL_FONT_OPEN_SANS_LIGHT_16PX
endif

#################
# sdk 1.6 supports ux_flow for the nano as well
DEFINES += HAVE_UX_FLOW

# if speculos simulator is selected enable debuging features
ifeq ($(SPECULOS), 1)
DEFINES += SPECULOS
DEBUG = 1
endif

ifeq ($(DEBUG),1)
    # Development flags
    APP_LOAD_PARAMS += --path "44'/01'"
    DEFINES += HAVE_BOLOS_APP_STACK_CANARY
    DEFINES += APP_DEBUG

    # we don't need printf
    DEFINES += HAVE_PRINTF PRINTF=
#    ifeq ($(TARGET_NAME),TARGET_NANOX)
#        DEFINES += HAVE_PRINTF PRINTF=mcu_usb_printf
#    else
#        DEFINES += HAVE_PRINTF PRINTF=screen_printf
#    endif
else
    # Release flags
    DEFINES += PRINTF\(...\)=
endif

##############
#  Compiler  #
##############
ifneq ($(BOLOS_ENV),)
$(info BOLOS_ENV=$(BOLOS_ENV))
CLANGPATH := $(BOLOS_ENV)/clang-arm-fropi/bin/
GCCPATH := $(BOLOS_ENV)/gcc-arm-none-eabi-5_3-2016q1/bin/
else
$(info BOLOS_ENV is not set: falling back to CLANGPATH and GCCPATH)
endif
ifeq ($(CLANGPATH),)
$(info CLANGPATH is not set: clang will be used from PATH)
endif
ifeq ($(GCCPATH),)
$(info GCCPATH is not set: arm-none-eabi-* will be used from PATH)
endif

CC := $(CLANGPATH)clang

ifeq ($(DEBUG),1)
CFLAGS += -O0 -g3
else
CFLAGS += -O2
endif

AS := $(GCCPATH)arm-none-eabi-gcc
AFLAGS +=

LD := $(GCCPATH)arm-none-eabi-gcc

ifeq ($(DEBUG),1)
LDFLAGS += -O0 -g3
else
LDFLAGS += -O2
endif

LDLIBS += -lm -lgcc -lc

# import rules to compile glyphs(/pone)
include $(BOLOS_SDK)/Makefile.glyphs

### variables processed by the common makefile.rules of the SDK to grab source files and include dirs
APP_SOURCE_PATH += src
SDK_SOURCE_PATH += lib_stusb lib_stusb_impl lib_u2f
SDK_SOURCE_PATH += lib_ux

ifeq ($(TARGET_NAME),TARGET_NANOX)
    SDK_SOURCE_PATH += lib_blewbxx lib_blewbxx_impl
endif

load: all
	#echo python3 -m ledgerblue.loadApp $(APP_LOAD_PARAMS)
	python3 -m ledgerblue.loadApp $(APP_LOAD_PARAMS)

delete:
	python3 -m ledgerblue.deleteApp $(COMMON_DELETE_PARAMS)

# import generic rules from the sdk
include $(BOLOS_SDK)/Makefile.rules

#add dependency on custom makefile filename
dep/%.d: %.c Makefile



listvariants:
	@echo VARIANTS COIN iota
