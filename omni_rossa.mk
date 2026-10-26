# Release name
PRODUCT_RELEASE_NAME := rossa

$(call inherit-product, build/target/product/embedded.mk)

# Inherit from our custom product configuration
$(call inherit-product, vendor/omni/config/common.mk)

## Device identifier. This must come after all inclusions
PRODUCT_DEVICE := rossa
PRODUCT_NAME := omni_rossa
PRODUCT_BRAND := samsung
PRODUCT_MANUFACTURER := samsung
