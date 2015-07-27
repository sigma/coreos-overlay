# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-apps/systemd/systemd-9999.ebuild,v 1.169 2015/05/30 13:58:45 floppym Exp $

EAPI=5

CROS_WORKON_PROJECT="coreos/systemd"
CROS_WORKON_REPO="git://github.com"

if [[ "${PV}" == 9999 ]]; then
	# Use ~arch instead of empty keywords for compatibility with cros-workon
	KEYWORDS="~amd64 ~arm64 ~arm ~x86"
else
	CROS_WORKON_COMMIT="02a5fafc496e9cdea345866cdc7d908da4e115a1"
	KEYWORDS="amd64 arm64 ~arm ~x86"
fi

# cros-workon must be imported first, in cases where cros-workon and
# another eclass exports the same function (say src_compile) we want
# the later eclass's version to win. Only need src_unpack from workon.
inherit cros-workon

AUTOTOOLS_AUTORECONF=yes
AUTOTOOLS_PRUNE_LIBTOOL_FILES=all
PYTHON_COMPAT=( python{2_7,3_3,3_4} )
inherit autotools-utils bash-completion-r1 linux-info multilib \
	multilib-minimal pam python-single-r1 systemd toolchain-funcs udev \
	user

DESCRIPTION="System and service manager for Linux"
HOMEPAGE="http://www.freedesktop.org/wiki/Software/systemd"

LICENSE="GPL-2 LGPL-2.1 MIT public-domain"
SLOT="0/2"
IUSE="acl apparmor audit cryptsetup curl doc elfutils gcrypt gnuefi gudev http
	idn +importd introspection kdbus +kmod +lz4 lzma nat pam policykit python
	qrcode +seccomp selinux ssl sysv-utils terminal test vanilla xkb"

# Gentoo removed the nls use flag, we'll keep it for now
IUSE+=" nls symlink-usr"

REQUIRED_USE="importd? ( curl gcrypt lzma )"

MINKV="3.8"

COMMON_DEPEND=">=sys-apps/util-linux-2.25:0=
	sys-libs/libcap:0=
	!<sys-libs/glibc-2.16
	acl? ( sys-apps/acl:0= )
	apparmor? ( sys-libs/libapparmor:0= )
	audit? ( >=sys-process/audit-2:0= )
	cryptsetup? ( >=sys-fs/cryptsetup-1.6:0= )
	curl? ( net-misc/curl:0= )
	elfutils? ( >=dev-libs/elfutils-0.158:0= )
	gcrypt? ( >=dev-libs/libgcrypt-1.4.5:0=[${MULTILIB_USEDEP}] )
	gudev? ( >=dev-libs/glib-2.34.3:2=[${MULTILIB_USEDEP}] )
	http? (
		>=net-libs/libmicrohttpd-0.9.33:0=
		ssl? ( >=net-libs/gnutls-3.1.4:0= )
	)
	idn? ( net-dns/libidn:0= )
	importd? (
		app-arch/bzip2:0=
		sys-libs/zlib:0=
	)
	introspection? ( >=dev-libs/gobject-introspection-1.31.1:0= )
	kmod? ( >=sys-apps/kmod-15:0= )
	lz4? ( >=app-arch/lz4-0_p119:0=[${MULTILIB_USEDEP}] )
	lzma? ( >=app-arch/xz-utils-5.0.5-r1:0=[${MULTILIB_USEDEP}] )
	nat? ( net-firewall/iptables:0= )
	pam? ( virtual/pam:= )
	python? ( ${PYTHON_DEPS} )
	qrcode? ( media-gfx/qrencode:0= )
	seccomp? ( sys-libs/libseccomp:0= )
	selinux? ( sys-libs/libselinux:0= )
	sysv-utils? (
		!sys-apps/systemd-sysv-utils
		!sys-apps/sysvinit )
	terminal? ( >=dev-libs/libevdev-1.2:0=
		>=x11-libs/libxkbcommon-0.5:0=
		>=x11-libs/libdrm-2.4:0= )
	xkb? ( >=x11-libs/libxkbcommon-0.4.1:0= )
	abi_x86_32? ( !<=app-emulation/emul-linux-x86-baselibs-20130224-r9
		!app-emulation/emul-linux-x86-baselibs[-abi_x86_32(-)] )"

# baselayout-2.2 has /run
RDEPEND="${COMMON_DEPEND}
	>=sys-apps/baselayout-2.2
	!sys-auth/nss-myhostname
	!sys-fs/eudev
	!sys-fs/udev"

# sys-apps/dbus: the daemon only (+ build-time lib dep for tests)
PDEPEND=">=sys-apps/dbus-1.6.8-r1:0[systemd]
	>=sys-apps/hwids-20130717-r1[udev]
	policykit? ( sys-auth/polkit )
	!vanilla? ( sys-apps/gentoo-systemd-integration )"

# Newer linux-headers needed by ia64, bug #480218
DEPEND="${COMMON_DEPEND}
	app-arch/xz-utils:0
	dev-util/gperf
	>=dev-util/intltool-0.50
	>=sys-apps/coreutils-8.16
	>=sys-devel/binutils-2.23.1
	>=sys-devel/gcc-4.6
	>=sys-kernel/linux-headers-${MINKV}
	ia64? ( >=sys-kernel/linux-headers-3.9 )
	virtual/pkgconfig
	doc? ( >=dev-util/gtk-doc-1.18 )
	gnuefi? ( >=sys-boot/gnu-efi-3.0.2 )
	python? ( dev-python/lxml[${PYTHON_USEDEP}] )
	terminal? ( media-fonts/unifont[utils(+)] )
	test? ( >=sys-apps/dbus-1.6.8-r1:0 )"

# Not required when building from unpatched tarballs, but we build from git.
DEPEND="${DEPEND}
	app-text/docbook-xml-dtd:4.2
	app-text/docbook-xml-dtd:4.5
	app-text/docbook-xsl-stylesheets
	dev-libs/libxslt:0
	dev-libs/gobject-introspection
	>=dev-libs/libgcrypt-1.4.5:0"

pkg_pretend() {
	local CONFIG_CHECK="~AUTOFS4_FS ~BLK_DEV_BSG ~CGROUPS
		~DEVPTS_MULTIPLE_INSTANCES ~DEVTMPFS ~DMIID ~EPOLL ~FANOTIFY ~FHANDLE
		~INOTIFY_USER ~IPV6 ~NET ~NET_NS ~PROC_FS ~SECCOMP ~SIGNALFD ~SYSFS
		~TIMERFD ~TMPFS_XATTR
		~!FW_LOADER_USER_HELPER ~!GRKERNSEC_PROC ~!IDE ~!SYSFS_DEPRECATED
		~!SYSFS_DEPRECATED_V2"

	use acl && CONFIG_CHECK+=" ~TMPFS_POSIX_ACL"
	kernel_is -lt 3 7 && CONFIG_CHECK+=" ~HOTPLUG"

	if linux_config_exists; then
		local uevent_helper_path=$(linux_chkconfig_string UEVENT_HELPER_PATH)
			if [ -n "${uevent_helper_path}" ] && [ "${uevent_helper_path}" != '""' ]; then
				ewarn "It's recommended to set an empty value to the following kernel config option:"
				ewarn "CONFIG_UEVENT_HELPER_PATH=${uevent_helper_path}"
			fi
	fi

	if [[ ${MERGE_TYPE} != binary ]]; then
		if [[ $(gcc-major-version) -lt 4
			|| ( $(gcc-major-version) -eq 4 && $(gcc-minor-version) -lt 6 ) ]]
		then
			eerror "systemd requires at least gcc 4.6 to build. Please switch the active"
			eerror "gcc version using gcc-config."
			die "systemd requires at least gcc 4.6"
		fi
	fi

	if [[ ${MERGE_TYPE} != buildonly ]]; then
		if kernel_is -lt ${MINKV//./ }; then
			ewarn "Kernel version at least ${MINKV} required"
		fi

		check_extra_config
	fi
}

pkg_setup() {
	use python && python-single-r1_pkg_setup
}

src_prepare() {
	if use doc; then
		gtkdocize --docdir docs/ || die
	else
		echo 'EXTRA_DIST =' > docs/gtk-doc.make
	fi

	# Bug 463376
	sed -i -e 's/GROUP="dialout"/GROUP="uucp"/' rules/*.rules || die

	autotools-utils_src_prepare
}

src_configure() {
	# Keep using the one where the rules were installed.
	MY_UDEVDIR=$(get_udevdir)
	# Fix systems broken by bug #509454.
	[[ ${MY_UDEVDIR} ]] || MY_UDEVDIR=/lib/udev

	multilib-minimal_src_configure
}

multilib_src_configure() {
	local myeconfargs=(
		--with-pamconfdir=/usr/share/pam.d

		# Workaround for bug 516346
		--enable-dependency-tracking

		--disable-maintainer-mode
		--localstatedir=/var
		--with-pamlibdir=$(getpam_mod_dir)
		# avoid bash-completion dep
		--with-bashcompletiondir="$(get_bashcompdir)"
		# make sure we get /bin:/sbin in $PATH
		--enable-split-usr
		# For testing.
		--with-rootprefix="${ROOTPREFIX-/usr}"
		--with-rootlibdir="${ROOTPREFIX-/usr}/$(get_libdir)"
		# disable sysv compatibility
		--with-sysvinit-path=
		--with-sysvrcnd-path=
		# no deps
		--enable-efi
		--enable-ima
		# used for stacktraces in log messages, leave off for now
		--disable-elfutils

		# Optional components/dependencies
		$(multilib_native_use_enable acl)
		$(multilib_native_use_enable apparmor)
		$(multilib_native_use_enable audit)
		$(multilib_native_use_enable cryptsetup libcryptsetup)
		$(multilib_native_use_enable curl libcurl)
		$(multilib_native_use_enable doc gtk-doc)
		$(multilib_native_use_enable elfutils)
		$(use_enable gcrypt)
		$(multilib_native_use_enable gnuefi)
		$(use_enable gudev)
		$(multilib_native_use_enable http microhttpd)
		$(usex http $(multilib_native_use_enable ssl gnutls) --disable-gnutls)
		$(multilib_native_use_enable idn libidn)
		$(multilib_native_use_enable importd)
		$(multilib_native_use_enable importd bzip2)
		$(multilib_native_use_enable importd zlib)
		$(multilib_native_use_enable introspection)
		$(use_enable kdbus)
		$(multilib_native_use_enable kmod)
		$(use_enable lz4)
		$(use_enable lzma xz)
		$(multilib_native_use_enable nat libiptc)
		$(use_enable nls)
		$(multilib_native_use_enable pam)
		$(multilib_native_use_enable policykit polkit)
		$(multilib_native_use_with python)
		$(multilib_native_use_enable python python-devel)
		$(multilib_native_use_enable qrcode qrencode)
		$(multilib_native_use_enable seccomp)
		$(multilib_native_use_enable selinux)
		$(multilib_native_use_enable terminal)
		$(multilib_native_use_enable test tests)
		$(multilib_native_use_enable test dbus)
		$(multilib_native_use_enable xkb xkbcommon)

		# not supported (avoid automagic deps in the future)
		--disable-chkconfig

		# hardcode a few paths to spare some deps
		QUOTAON=/usr/sbin/quotaon
		QUOTACHECK=/usr/sbin/quotacheck

		# TODO: we may need to restrict this to gcc
		EFI_CC="$(tc-getCC)"

		# dbus paths
		--with-dbuspolicydir="${EPREFIX}/usr/share/dbus-1/system.d"
		--with-dbussessionservicedir="${EPREFIX}/usr/share/dbus-1/services"
		--with-dbussystemservicedir="${EPREFIX}/usr/share/dbus-1/system-services"
		--with-dbusinterfacedir="${EPREFIX}/usr/share/dbus-1/interfaces"

		--with-ntp-servers="0.coreos.pool.ntp.org 1.coreos.pool.ntp.org 2.coreos.pool.ntp.org 3.coreos.pool.ntp.org"

		# no default name servers
		--with-dns-servers=
	)

	if ! multilib_is_native_abi; then
		myeconfargs+=(
			MOUNT_{CFLAGS,LIBS}=' '

			ac_cv_search_cap_init=
			ac_cv_header_sys_capability_h=yes
		)
	fi

	# Work around bug 463846.
	tc-export CC

	autotools-utils_src_configure
}

multilib_src_compile() {
	local mymakeopts=(
		udevlibexecdir="${MY_UDEVDIR}"
	)

	if multilib_is_native_abi; then
		emake "${mymakeopts[@]}"
	else
		# prerequisites for gudev
		use gudev && emake src/gudev/gudev{enumtypes,marshal}.{c,h}

		echo 'gentoo: $(BUILT_SOURCES)' | \
		emake "${mymakeopts[@]}" -f Makefile -f - gentoo
		echo 'gentoo: $(lib_LTLIBRARIES) $(pkgconfiglib_DATA)' | \
		emake "${mymakeopts[@]}" -f Makefile -f - gentoo
	fi
}

multilib_src_test() {
	multilib_is_native_abi || continue

	default
}

multilib_src_install() {
	local mymakeopts=(
		# automake fails with parallel libtool relinking
		# https://bugs.gentoo.org/show_bug.cgi?id=491398
		-j1

		udevlibexecdir="${MY_UDEVDIR}"
		dist_udevhwdb_DATA=
		DESTDIR="${D}"
	)

	if multilib_is_native_abi; then
		emake "${mymakeopts[@]}" install
	else
		mymakeopts+=(
			install-libLTLIBRARIES
			install-pkgconfiglibDATA
			install-includeHEADERS
			# safe to call unconditionally, 'installs' empty list
			install-libgudev_includeHEADERS
			install-pkgincludeHEADERS
		)

		emake "${mymakeopts[@]}"
	fi

	# install compat pkg-config files
	# Change dbus to >=sys-apps/dbus-1.8.8 if/when this is dropped.
	local pcfiles=( src/compat-libs/libsystemd-{daemon,id128,journal,login}.pc )
	emake "${mymakeopts[@]}" install-pkgconfiglibDATA \
		pkgconfiglib_DATA="${pcfiles[*]}"
}

multilib_src_install_all() {
	local unitdir=$(systemd_get_unitdir)

	prune_libtool_files --modules
	einstalldocs

	if use sysv-utils; then
		local prefix
		use symlink-usr && prefix=/usr
		for app in halt poweroff reboot runlevel shutdown telinit; do
			dosym "${ROOTPREFIX-/usr}/bin/systemctl" ${prefix}/sbin/${app}
		done
		dosym "${ROOTPREFIX-/usr}/lib/systemd/systemd" ${prefix}/sbin/init
	else
		# we just keep sysvinit tools, so no need for the mans
		rm "${D}"/usr/share/man/man8/{halt,poweroff,reboot,runlevel,shutdown,telinit}.8 \
			|| die
		rm "${D}"/usr/share/man/man1/init.1 || die
	fi

	# Ensure journal directory has correct ownership/mode in inital image.
	# This is fixed by systemd-tmpfiles *but* journald starts before that
	# and will create the journal if the filesystem is already read-write.
	# Conveniently the systemd Makefile sets this up completely wrong.
	dodir /var/log/journal
	fowners root:systemd-journal /var/log/journal
	fperms 2755 /var/log/journal

	systemd_dotmpfilesd "${FILESDIR}"/systemd-coreos.conf
	systemd_dotmpfilesd "${FILESDIR}"/systemd-resolv.conf

	# Don't default to graphical.target
	rm "${D}${unitdir}"/default.target || die
	dosym multi-user.target "${unitdir}"/default.target

	# Move a few services enabled in /etc to /usr, delete files individually
	# so builds fail if systemd adds any new unexpected stuff to /etc
	local f
	for f in \
		getty.target.wants/getty@tty1.service \
		multi-user.target.wants/remote-fs.target \
		multi-user.target.wants/systemd-networkd.service \
		multi-user.target.wants/systemd-resolved.service \
		network-online.target.wants/systemd-networkd-wait-online.service \
		sockets.target.wants/systemd-networkd.socket \
		sysinit.target.wants/systemd-timesyncd.service
	do
		local s="${f#*/}" t="${f%/*}"
		local u="${s/@*.service/@.service}"

		# systemd_enable_service doesn't understand template units
		einfo "Enabling ${s} via ${t}"
		dodir "${unitdir}/${t}"
		dosym "../${u}" "${unitdir}/${t}/${s}"

		rm "${D}/etc/systemd/system/${f}" || die
	done
	rmdir "${D}"/etc/systemd/system/*.wants || die

	# Grant networkd access to set the transient host name
	insinto /usr/share/polkit-1/rules.d
	doins "${FILESDIR}"/99-org.freedesktop.hostname1.rules

	# Do not enable random services if /etc was detected as empty!!!
	rm "${D}"/usr/lib/systemd/system-preset/90-systemd.preset
	insinto /usr/lib/systemd/system-preset
	doins "${FILESDIR}"/99-default.preset

	# Disable the "First Boot Wizard" by default, it isn't very applicable to CoreOS
	rm "${D}${unitdir}"/sysinit.target.wants/systemd-firstboot.service

	# Do not ship distro-specific files (nsswitch.conf pam.d)
	rm -rf "${D}"/usr/share/factory
	sed -i "${D}"/usr/lib/tmpfiles.d/etc.conf \
		-e '/^C \/etc\/nsswitch\.conf/d' \
		-e '/^C \/etc\/pam\.d/d'
}

migrate_locale() {
	local envd_locale_def="${EROOT%/}/etc/env.d/02locale"
	local envd_locale=( "${EROOT%/}"/etc/env.d/??locale )
	local locale_conf="${EROOT%/}/etc/locale.conf"

	if [[ ! -L ${locale_conf} && ! -e ${locale_conf} ]]; then
		# If locale.conf does not exist...
		if [[ -e ${envd_locale} ]]; then
			# ...either copy env.d/??locale if there's one
			ebegin "Moving ${envd_locale} to ${locale_conf}"
			mv "${envd_locale}" "${locale_conf}"
			eend ${?} || FAIL=1
		else
			# ...or create a dummy default
			ebegin "Creating ${locale_conf}"
			cat > "${locale_conf}" <<-EOF
				# This file has been created by the sys-apps/systemd ebuild.
				# See locale.conf(5) and localectl(1).

				# LANG=${LANG}
			EOF
			eend ${?} || FAIL=1
		fi
	fi

	if [[ ! -L ${envd_locale} ]]; then
		# now, if env.d/??locale is not a symlink (to locale.conf)...
		if [[ -e ${envd_locale} ]]; then
			# ...warn the user that he has duplicate locale settings
			ewarn
			ewarn "To ensure consistent behavior, you should replace ${envd_locale}"
			ewarn "with a symlink to ${locale_conf}. Please migrate your settings"
			ewarn "and create the symlink with the following command:"
			ewarn "ln -s -n -f ../locale.conf ${envd_locale}"
			ewarn
		else
			# ...or just create the symlink if there's nothing here
			ebegin "Creating ${envd_locale_def} -> ../locale.conf symlink"
			ln -n -s ../locale.conf "${envd_locale_def}"
			eend ${?} || FAIL=1
		fi
	fi
}

migrate_net_name_slot() {
	# If user has disabled 80-net-name-slot.rules using a empty file or a symlink to /dev/null,
	# do the same for 80-net-setup-link.rules to keep the old behavior
	local net_move=no
	local net_name_slot_sym=no
	local net_rules_path="${EROOT%/}"/etc/udev/rules.d
	local net_name_slot="${net_rules_path}"/80-net-name-slot.rules
	local net_setup_link="${net_rules_path}"/80-net-setup-link.rules
	if [[ -e ${net_setup_link} ]]; then
		net_move=no
	elif [[ -f ${net_name_slot} && $(sed -e "/^#/d" -e "/^\W*$/d" ${net_name_slot} | wc -l) == 0 ]]; then
		net_move=yes
	elif [[ -L ${net_name_slot} && $(readlink ${net_name_slot}) == /dev/null ]]; then
		net_move=yes
		net_name_slot_sym=yes
	fi
	if [[ ${net_move} == yes ]]; then
		ebegin "Copying ${net_name_slot} to ${net_setup_link}"

		if [[ ${net_name_slot_sym} == yes ]]; then
			ln -nfs /dev/null "${net_setup_link}"
		else
			cp "${net_name_slot}" "${net_setup_link}"
		fi
		eend $? || FAIL=1
	fi
}

pkg_postinst() {
	newusergroup() {
		enewgroup "$1"
		enewuser "$1" -1 -1 -1 "$1"
	}

	enewgroup input
	enewgroup systemd-journal
	newusergroup systemd-bus-proxy
	newusergroup systemd-journal-gateway
	newusergroup systemd-journal-remote
	newusergroup systemd-journal-upload
	newusergroup systemd-network
	newusergroup systemd-resolve
	newusergroup systemd-timesync
	use http && newusergroup systemd-journal-gateway

	systemd_update_catalog

	# Keep this here in case the database format changes so it gets updated
	# when required. Despite that this file is owned by sys-apps/hwids.
	if has_version "sys-apps/hwids[udev]"; then
		udevadm hwdb --update --root="${ROOT%/}"
	fi

	udev_reload || FAIL=1

	# Bug 465468, make sure locales are respect, and ensure consistency
	# between OpenRC & systemd
	migrate_locale

	# Migrate 80-net-name-slot.rules -> 80-net-setup-link.rules
	migrate_net_name_slot

	if [[ ${FAIL} ]]; then
		eerror "One of the postinst commands failed. Please check the postinst output"
		eerror "for errors. You may need to clean up your system and/or try installing"
		eerror "systemd again."
		eerror
	fi

	if [[ $(readlink "${ROOT}"/etc/resolv.conf) == */run/systemd/network/resolv.conf ]]; then
		ewarn "resolv.conf is now generated by systemd-resolved. To use it, enable"
		ewarn "systemd-resolved.service, and create a symlink from /etc/resolv.conf"
		ewarn "to /run/systemd/resolve/resolv.conf"
		ewarn
	fi
}

pkg_prerm() {
	# If removing systemd completely, remove the catalog database.
	if [[ ! ${REPLACED_BY_VERSION} ]]; then
		rm -f -v "${EROOT}"/var/lib/systemd/catalog/database
	fi
}
