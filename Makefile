THEOS_DEVICE_IP=Hirens-iPhone
export $THEOS_DEVICE_IP

include theos/makefiles/common.mk

TWEAK_NAME = iAnnounce
iAnnounce_FILES = Tweak.xm iAnnounceHelper.m
iAnnounce_FRAMEWORKS = AudioToolBox, UIKit, CoreTelephony
iAnnounce_PRIVATE_FRAMEWORKS = VoiceServices, Celestial

include $(FW_MAKEDIR)/tweak.mk
