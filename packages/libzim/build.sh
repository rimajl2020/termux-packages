TERMUX_PKG_HOMEPAGE=https://openzim.org
TERMUX_PKG_DESCRIPTION="The ZIM library is the reference implementation for the ZIM file format."
TERMUX_PKG_LICENSE="GPL-2.0"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION="9.3.0"
TERMUX_PKG_SRCURL=https://github.com/openzim/libzim/archive/$TERMUX_PKG_VERSION.tar.gz
TERMUX_PKG_SHA256=791220e51e6a160d349491b9744ec1a9c1a104f11a79e8e73673daf242be69ed
TERMUX_PKG_AUTO_UPDATE=true
TERMUX_PKG_DEPENDS="libc++, libicu, liblzma, libxapian, zstd"
TERMUX_PKG_BUILD_DEPENDS="googletest, libuuid"

termux_step_post_get_source() {
	# Do not forget to bump revision of reverse dependencies and rebuild them
	# after SOVERSION is changed.
	local _SOVERSION=9

	local v=$(echo ${TERMUX_PKG_VERSION#*:} | cut -d . -f 1)
	if [ "${v}" != "${_SOVERSION}" ]; then
		termux_error_exit "SOVERSION guard check failed."
	fi
}
