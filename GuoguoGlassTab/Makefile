ARCHS = arm64
TARGET = iphone:clang:latest:15.0
INSTALL_TARGET_PROCESSES = Runner

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = GuoguoGlassTab
GuoguoGlassTab_FILES = Tweak.xm GTGlassTabView.m Layout/GTLayout.c
GuoguoGlassTab_CFLAGS = -fobjc-arc -Wall -Wextra
GuoguoGlassTab_FRAMEWORKS = UIKit QuartzCore

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 Runner || true"

