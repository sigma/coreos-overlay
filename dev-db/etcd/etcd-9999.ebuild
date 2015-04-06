#
# Copyright (c) 2015 CoreOS, Inc.. All rights reserved.
# Distributed under the terms of the GNU General Public License v2
# $Header:$
#

EAPI=5
CROS_WORKON_PROJECT="coreos/etcd"
CROS_WORKON_LOCALNAME="etcd"
CROS_WORKON_REPO="git://github.com"
COREOS_GO_PACKAGE="github.com/coreos/etcd"
inherit coreos-doc coreos-go toolchain-funcs cros-workon

if [[ "${PV}" == 9999 ]]; then
    KEYWORDS="~amd64"
else
    CROS_WORKON_COMMIT="0cb90e4bea279eb207be3478affac7cc02692bec" # v2.0.7
    KEYWORDS="amd64"
fi

DESCRIPTION="etcd"
HOMEPAGE="https://github.com/coreos/etcd"
SRC_URI=""

LICENSE="Apache-2.0"
SLOT="2"
IUSE=""

DEPEND=">=dev-lang/go-1.2"
RDEPEND="!dev-db/etcd:0
	!dev-db/etcdctl"

src_compile() {
	go_build "${COREOS_GO_PACKAGE}"
	go_build "${COREOS_GO_PACKAGE}/etcdctl"
	go_build "${COREOS_GO_PACKAGE}/tools/etcd-migrate"
	go_build "${COREOS_GO_PACKAGE}/tools/etcd-dump-logs"
}

src_install() {
	local libexec="libexec/${PN}/internal_versions/${SLOT}"

	dobin ${WORKDIR}/gopath/bin/etcdctl
	dobin ${WORKDIR}/gopath/bin/etcd-migrate
	dobin ${WORKDIR}/gopath/bin/etcd-dump-logs

	exeinto "/usr/${libexec}"
	doexe "${WORKDIR}/gopath/bin/${PN}"

	coreos-dodoc -r Documentation/*
}
