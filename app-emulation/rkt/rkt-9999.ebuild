# Copyright (c) 2015 CoreOS, Inc.
# Distributed under the terms of the GNU General Public License v2

EAPI=5
CROS_WORKON_PROJECT="coreos/rkt"
CROS_WORKON_LOCALNAME="rkt"
CROS_WORKON_REPO="git://github.com"
inherit cros-workon systemd

if [[ "${PV}" == 9999 ]]; then
    KEYWORDS="~amd64"
else
    CROS_WORKON_COMMIT="40ced98c320c056e343fe9c3eaeb90a4ff248936" # v0.5.5
    KEYWORDS="amd64"
fi

# Must be in sync with stage1/rootfs/usr_from_coreos/cache.sh
IMG_RELEASE="444.5.0"
IMG_URL="http://stable.release.core-os.net/amd64-usr/${IMG_RELEASE}/coreos_production_pxe_image.cpio.gz"

DESCRIPTION="App Container runtime"
HOMEPAGE="https://github.com/coreos/rkt"
SRC_URI="${IMG_URL} -> pxe-${IMG_RELEASE}.img"

LICENSE="Apache-2.0"
SLOT="0"
IUSE=""

DEPEND=">=dev-lang/go-1.3
	app-arch/cpio
	sys-fs/squashfs-tools"
RDEPEND="!app-emulation/rocket"

src_unpack() {
	local cache="${S}/stage1/rootfs/usr_from_coreos/cache"

	cros-workon_src_unpack

	mkdir -p "${cache}" || die
	cp "${DISTDIR}/pxe-${IMG_RELEASE}.img" "${cache}/pxe.img" || die
}

# TODO: Use or adapt coreos-go.eclass so we have half a chance of
# cross-compiling builds working
src_compile() {
	RKT_STAGE1_IMAGE=/usr/share/rkt/stage1.aci CGO_ENABLED=0 ./build || die
}

src_install() {
	dobin "${S}/bin/rkt"

	insinto /usr/share/rkt
	doins "${S}/bin/stage1.aci"

	systemd_dounit "${FILESDIR}"/${PN}-gc.service
	systemd_dounit "${FILESDIR}"/${PN}-gc.timer
}
