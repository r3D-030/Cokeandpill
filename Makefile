export TARGET := iphone:clang:16.5:15.0
export ARCHS = arm64

INSTALL_TARGET_PROCESSES = Puccy

include $(THEOS)/makefiles/common.mk

APPLICATION_NAME = Puccy

Puccy_FILES = $(shell find Sources -name "*.swift" | tr '\n' ' ')
Puccy_FRAMEWORKS = UIKit SwiftUI UniformTypeIdentifiers
Puccy_PRIVATE_FRAMEWORKS = MobileCoreServices SpringBoardServices
Puccy_CODESIGN_FLAGS = -Sentitlements.plist
Puccy_SWIFTFLAGS = -DROOTLESS -DDEBUG
Puccy_INSTALL_PATH = /var/jb/Applications

include $(THEOS)/makefiles/application.mk
