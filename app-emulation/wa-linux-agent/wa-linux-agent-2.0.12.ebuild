#
# Copyright (c) 2014 CoreOS, Inc.. All rights reserved.
# Distributed under the terms of the GNU General Public License v2
# $Header:$
#

EAPI=4

EGIT_REPO_URI="git://github.com/Azure/WALinuxAgent"
EGIT_COMMIT="26785b64279913d416767a6288a3b3f970ed4522" # WALinuxAgent-2.0.12
EGIT_MASTER="2.0"

inherit eutils toolchain-funcs git-2

DESCRIPTION="Windows Azure Linux Agent"
HOMEPAGE="https://github.com/Azure/WALinuxAgent"
KEYWORDS="amd64"
SRC_URI=""

LICENSE="Apache-2.0"
SLOT="0"
IUSE=""

RDEPEND="dev-lang/python-oem"

src_install() {
	into "/usr/share/oem"
	dobin "${S}"/waagent

	insinto "/usr/share/oem"
	doins "${FILESDIR}"/waagent.conf
}
