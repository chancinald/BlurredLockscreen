#export target=simulator

ARCHS = armv7

include theos/makefiles/common.mk

BUNDLE_NAME = blurredlockscreensettings
blurredlockscreensettings_FILES = blurredlockscreensettings.mm blurredlockscreensettingsColorsController.mm
blurredlockscreensettings_INSTALL_PATH = /Library/PreferenceBundles
blurredlockscreensettings_FRAMEWORKS = UIKit
blurredlockscreensettings_PRIVATE_FRAMEWORKS = Preferences

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/blurredlockscreensettings.plist$(ECHO_END)
