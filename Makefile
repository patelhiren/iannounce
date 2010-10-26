include theos/makefiles/common.mk

TWEAK_NAME = iAnnounce
iAnnounce_FILES = Tweak.xm iAnnounceHelper.m
iAnnounce_FRAMEWORKS = AudioToolBox
iAnnounce_PRIVATE_FRAMEWORKS = VoiceServices, Celestial

include $(FW_MAKEDIR)/tweak.mk
