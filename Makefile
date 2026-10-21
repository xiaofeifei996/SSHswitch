export TARGET_CODESIGN_FLAGS = -Sentitlements.xml
# CI installs iPhoneOS15.6.sdk from theos/sdks; pin it so SYSROOT resolves.
export TARGET = iphone:clang:15.6:11.0
export ARCHS = arm64 arm64e
#messages=yes
export COPYFILE_DISABLE=1

PACKAGE_VERSION=$(shell cat "$(THEOS_PROJECT_DIR)/version.txt")

export THEOS_PACKAGE_SCHEME = $(if $(RF),,rootless)
export THEOS_PACKAGE_INSTALL_PREFIX = /var/jb
# ^ using this for older Theos, sort of backporting from post 2023-03-26 Theos (which sets this var automatically).

ifneq ($(THEOS_PACKAGE_SCHEME),rootless)
# reset the jb root prefix for rootful
export THEOS_PACKAGE_INSTALL_PREFIX =
endif

include $(THEOS)/makefiles/common.mk

TOOL_NAME = SSHswitch
$(TOOL_NAME)_CFLAGS += -fvisibility=hidden -DBUILD_VERSION="\"$(PACKAGE_VERSION)\"" -I$(THEOS_PROJECT_DIR)/include
$(TOOL_NAME)_FILES = SSHswitch.c
# Theos introduced modularized schemes 2024-02-18 and since that the install prefix is automatic.
ifeq ($(THEOS_VENDOR_MODULE_PATH),)
$(TOOL_NAME)_INSTALL_PATH = $(THEOS_PACKAGE_INSTALL_PREFIX)/usr/bin/
# ^ this prefix isn't necessary with newer Theos but for pre 2023-03-26 ones it's easier if the path already includes it.
else
$(TOOL_NAME)_INSTALL_PATH = /usr/bin/
# ^ THEOS_PACKAGE_INSTALL_PREFIX is being prepended automatically by Theos since 2024-02-18 when the schemes got modularized.
export THEOS_VENDOR_MODULE_PATH
# ^ for makeDoc.sh, so it knows not to force the /var/jb prefix in before-stage::
endif

# control file which we make in before-stage:: (want to make sure the arch is right, whatever was last manually written there)
_THEOS_DEB_PACKAGE_CONTROL_PATH = "$(THEOS_PROJECT_DIR)/control-$(THEOS_PACKAGE_SCHEME)"

ifeq ($(THEOS_PACKAGE_SCHEME),rootless)
ifneq ($(THEOS_PACKAGE_ARCH),iphoneos-arm64)
# so this must be some older (pre 2023-03-26) Theos, need to mangle things a bit when packaging. 

# for the filename and for the arch in before-stage::
THEOS_PACKAGE_ARCH = iphoneos-arm64

before-package::
# some backporting from Theos makefiles/package/deb.mk post 2023-03-26 internal-package::
	$(ECHO_NOTHING)mkdir -p "$(THEOS_STAGING_DIR)$(THEOS_PACKAGE_INSTALL_PREFIX)"$(ECHO_END)
	$(ECHO_NOTHING)rsync -a "$(THEOS_STAGING_DIR)/" "$(THEOS_STAGING_DIR)$(THEOS_PACKAGE_INSTALL_PREFIX)" --exclude "DEBIAN" --exclude "$(THEOS_PACKAGE_INSTALL_PREFIX)" $(_THEOS_RSYNC_EXCLUDE_COMMANDLINE) $(ECHO_END)
	$(ECHO_NOTHING)find "$(THEOS_STAGING_DIR)" -mindepth 1 -maxdepth 1 ! -name DEBIAN ! -name "var" -exec rm -rf {} \;$(ECHO_END)
	$(ECHO_NOTHING)rmdir "$(THEOS_STAGING_DIR)$(THEOS_PACKAGE_INSTALL_PREFIX)/var" >/dev/null 2>&1 || true$(ECHO_END)

endif
else ifeq ($(THEOS_PACKAGE_SCHEME),)
# rootful only: roothide module supplies iphoneos-arm64e itself
THEOS_PACKAGE_ARCH = iphoneos-arm
endif

before-stage::
	$(ECHO_NOTHING)sed -E 's/Architecture: iphoneos-arm.*/Architecture: $(THEOS_PACKAGE_ARCH)/' "$(THEOS_PROJECT_DIR)/control" > "$(THEOS_PROJECT_DIR)/control-$(THEOS_PACKAGE_SCHEME)"$(ECHO_END)
	$(ECHO_NOTHING)rm -rf $(THEOS_PROJECT_DIR)/layout/usr $(THEOS_PROJECT_DIR)/layout/var$(ECHO_END)
	$(ECHO_NOTHING)sed -E 's/THISVER=.+/THISVER=$(PACKAGE_VERSION)/g' $(THEOS_PROJECT_DIR)/layout/DEBIAN/postrm > $(THEOS_PROJECT_DIR)/layout/DEBIAN/postrm.current && chmod 0755 $(THEOS_PROJECT_DIR)/layout/DEBIAN/postrm.current && mv -f $(THEOS_PROJECT_DIR)/layout/DEBIAN/postrm.current $(THEOS_PROJECT_DIR)/layout/DEBIAN/postrm || true$(ECHO_END)
	$(ECHO_NOTHING)$(THEOS_PROJECT_DIR)/doc/makeDoc.sh$(ECHO_END)

after-stage::
	$(ECHO_NOTHING)find $(THEOS_STAGING_DIR) -name .DS_Store | xargs rm -rf$(ECHO_END)
	$(ECHO_NOTHING)find $(THEOS_STAGING_DIR) -name "*~" | xargs rm -f$(ECHO_END)
	$(ECHO_NOTHING)chmod 6755 $(THEOS_STAGING_DIR)/usr/bin/$(TOOL_NAME) $(THEOS_STAGING_DIR)$(THEOS_PACKAGE_INSTALL_PREFIX)/usr/bin/$(TOOL_NAME) 2>/dev/null || true$(ECHO_END)

after-package::
	$(ECHO_NOTHING)rm -f "$(THEOS_PROJECT_DIR)/control-$(THEOS_PACKAGE_SCHEME)" >/dev/null || true$(ECHO_END)

include $(THEOS_MAKE_PATH)/tool.mk

