TERMUX_PKG_HOMEPAGE=https://www.erlang.org/
TERMUX_PKG_DESCRIPTION="General-purpose concurrent functional programming language"
TERMUX_PKG_LICENSE="Apache-2.0"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION="28.0.2"
TERMUX_PKG_SRCURL=https://github.com/erlang/otp/archive/refs/tags/OTP-$TERMUX_PKG_VERSION.tar.gz
TERMUX_PKG_SHA256=ae202078906c10d1c107ba8d580e22062432fc602fb1483a2972d886bd426f5e
TERMUX_PKG_AUTO_UPDATE=true
TERMUX_PKG_UPDATE_VERSION_REGEXP='\d+(\.\d+)+'
TERMUX_PKG_DEPENDS="libc++, openssl, ncurses, zlib"
TERMUX_PKG_NO_STATICSPLIT=true
TERMUX_PKG_HOSTBUILD=true
TERMUX_PKG_BUILD_IN_SRC=true
TERMUX_PKG_EXTRA_CONFIGURE_ARGS="
--without-javac
--with-ssl=${TERMUX_PREFIX}
--with-termcap
erl_xcomp_sysroot=${TERMUX_PREFIX}
"
# for some reason, these do not work properly, and are duplicates
# of ones patched to work which are installed into $TERMUX_PREFIX/share/man/man1
TERMUX_PKG_RM_AFTER_INSTALL="
lib/erlang/man
"

termux_pkg_auto_update() {
	# Get latest release tag:
	local tag
	tag="$(termux_github_api_get_tag "${TERMUX_PKG_SRCURL}")"
	# check if this is not an intermediate release candidate:
	if grep -qP "^OTP-${TERMUX_PKG_UPDATE_VERSION_REGEXP}\$" <<<"$tag"; then
		termux_pkg_upgrade_version "$tag"
	else
		echo "WARNING: Skipping auto-update: Not stable release($tag)"
	fi
}

termux_step_post_get_source() {
	# We need a host build every time, because we dont know the full output of host build and have no idea to cache it.
	rm -Rf "$TERMUX_PKG_HOSTBUILD_DIR"
}

termux_step_host_build() {
	cd $TERMUX_PKG_BUILDDIR
	# Erlang cross compile reference: https://github.com/erlang/otp/blob/master/HOWTO/INSTALL-CROSS.md#building-a-bootstrap-system
	# Build erlang bootstrap system.
	# the prefix must be set to $TERMUX_PREFIX here to install the documentation where desired
	# without making a mess.
	./configure --prefix="$TERMUX_PREFIX" --without-javac --with-termcap
	make -j $TERMUX_PKG_MAKE_PROCESSES
	make RELSYS_MANDIR="$TERMUX_PREFIX/share/man" install-docs
}

termux_step_pre_configure() {
	# Add --build flag for erlang cross build
	TERMUX_PKG_EXTRA_CONFIGURE_ARGS+=" --build=$(./erts/autoconf/config.guess)"

	# https://android.googlesource.com/platform/bionic/+/master/docs/32-bit-abi.md#is-32_bit-on-lp32-y2038
	if [ $TERMUX_ARCH_BITS = 32 ]; then
		TERMUX_PKG_EXTRA_CONFIGURE_ARGS+=" --disable-year2038"
	fi

	# Use a wrapper CC to move `-I@TERMUX_PREFIX@/include` to the last include param
	mkdir -p $TERMUX_PKG_TMPDIR/_fake_bin
	sed -e "s|@TERMUX_PREFIX@|${TERMUX_PREFIX}|g" \
		-e "s|@COMPILER@|$(command -v ${CC})|g" \
		"$TERMUX_PKG_BUILDER_DIR"/wrapper.py.in \
		> $TERMUX_PKG_TMPDIR/_fake_bin/"$(basename ${CC})"
	chmod +x $TERMUX_PKG_TMPDIR/_fake_bin/"$(basename ${CC})"
	export PATH="$TERMUX_PKG_TMPDIR/_fake_bin:$PATH"
}
