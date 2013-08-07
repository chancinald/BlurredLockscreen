#export target=simulator

ARCHS = armv7
#TARGET = iphone:6.0

include theos/makefiles/common.mk

GO_EASY_ON_ME = 1

TWEAK_NAME = BlurredLockScreen
BlurredLockScreen_FILES = Tweak.xm SettingsHandler.m

BlurredLockScreen_FRAMEWORKS = UIKit CoreGraphics QuartzCore

SUBPROJECTS = blurredlockscreensettings

include $(THEOS_MAKE_PATH)/aggregate.mk
include $(THEOS_MAKE_PATH)/tweak.mk
