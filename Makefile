ARCHS = armv7
TARGET = iPhone:latest:4.3
#export target=simulator

include theos/makefiles/common.mk

TWEAK_NAME = BlurredLockScreen
BlurredLockScreen_FILES = Tweak.xm SettingsHandler.m

BlurredLockScreen_FRAMEWORKS = UIKit CoreGraphics QuartzCore

SUBPROJECTS = blurredlockscreensettings

include $(THEOS_MAKE_PATH)/aggregate.mk
include $(THEOS_MAKE_PATH)/tweak.mk
