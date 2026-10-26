#
# Credits to https://github.com/Galaxy-MSM8916/android_device_samsung_msm8916-common
#

LOCAL_PATH := $(call my-dir)

## Build and run dtbtool (from Snippet 1)
DTBTOOL := $(HOST_OUT_EXECUTABLES)/dtbToolCM$(HOST_EXECUTABLE_PREFIX)
INSTALLED_DTIMAGE_TARGET := $(PRODUCT_OUT)/dt.img

ifneq ($(TARGET_KERNEL_ARCH),)
KERNEL_ARCH := $(TARGET_KERNEL_ARCH)
else
KERNEL_ARCH := $(TARGET_ARCH)
endif

# Generate the dtimage
$(INSTALLED_DTIMAGE_TARGET): $(DTBTOOL) $(TARGET_OUT_INTERMEDIATES)/KERNEL_OBJ/usr $(INSTALLED_KERNEL_TARGET)
	$(call pretty,"Target dt image: $(INSTALLED_DTIMAGE_TARGET)")
	$(hide) $(DTBTOOL) $(BOARD_DTBTOOL_ARGS) -o $(INSTALLED_DTIMAGE_TARGET) -s $(BOARD_KERNEL_PAGESIZE) -p $(KERNEL_OUT)/scripts/dtc/ $(KERNEL_OUT)/arch/$(KERNEL_ARCH)/boot/dts/
	@echo -e ${CL_CYN}"Made DT image: $@"${CL_RST}

## TWRP Recovery Variables (from Snippet 2)
MKBOOTIMG := device/samsung/rossa/mkbootimg
TWRP_VERSION := $(shell cat bootable/recovery/variables.h | grep "define TW_MAIN_VERSION_STR" | cut -d\" -f2)
TWRP_NAME := recovery-TWRP-$(TWRP_VERSION)-rossa-$(shell date +%Y-%m-%d-%H.%M.%S)

BUILT_RAMDISK_CPIO := $(PRODUCT_OUT)/ramdisk-recovery.cpio
COMPRESS_COMMAND := xz --format=lzma --lzma1=dict=16MiB -9

## Recovery Image Generation & Packaging (Snippet 2 structure + Snippet 1 non-prebuilt logic)
INSTALLED_RECOVERYIMAGE_TARGET := $(PRODUCT_OUT)/recovery.img
$(INSTALLED_RECOVERYIMAGE_TARGET): $(MKBOOTIMG) $(INSTALLED_DTIMAGE_TARGET) \
		$(recovery_ramdisk) \
		$(recovery_kernel)
	@echo "------- Compressing recovery ramdisk -------"
	$(hide) $(COMPRESS_COMMAND) "$(BUILT_RAMDISK_CPIO)"
	@echo "------- Making recovery image -------"
	$(hide) $(MKBOOTIMG) \
		--kernel $(recovery_kernel) \
		--ramdisk $(BUILT_RAMDISK_CPIO).lzma \
		--cmdline "$(BOARD_KERNEL_CMDLINE)" \
		--base $(BOARD_KERNEL_BASE) \
		--pagesize $(BOARD_KERNEL_PAGESIZE) \
		--dt $(INSTALLED_DTIMAGE_TARGET) \
		--tags_offset $(BOARD_KERNEL_TAGS_OFFSET) \
		--ramdisk_offset $(BOARD_RAMDISK_OFFSET) \
		$(BOARD_MKBOOTIMG_ARGS) \
		-o $(INSTALLED_RECOVERYIMAGE_TARGET)
	$(hide) cp $(PRODUCT_OUT)/recovery.img $(PRODUCT_OUT)/$(TWRP_NAME).img
	@echo "------- Made recovery image: $@ -------"
	$(hide) echo -n "SEANDROIDENFORCE" >> $(INSTALLED_RECOVERYIMAGE_TARGET)
	@echo "------- Lied about SEAndroid state to Samsung bootloader -------"
	$(hide) cd $(PRODUCT_OUT) && tar -H ustar -c $(shell basename $@) > $(TWRP_NAME).tar
	$(hide) cd $(PRODUCT_OUT) && md5sum -t $(TWRP_NAME).tar >> $(TWRP_NAME).tar
	$(hide) mv $(PRODUCT_OUT)/$(TWRP_NAME).tar $(PRODUCT_OUT)/$(TWRP_NAME).tar.md5
	@echo "------- Made flashable image: $(PRODUCT_OUT)/$(TWRP_NAME).tar.md5 -------"