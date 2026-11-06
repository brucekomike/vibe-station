#!/bin/bash
# install macports base on the legacy station: intel hardware, macOS 15 sequoia.
# run before bootstrap-ports.sh.
set -euo pipefail

macports_version=2.12.7
release_base=https://github.com/macports/macports-base/releases/download
pkg=MacPorts-${macports_version}-15-Sequoia.pkg
chk=MacPorts-${macports_version}.chk.txt

# sequoia is the last release that runs on intel — refuse to install the pkg
# anywhere else
sw_vers -productVersion | grep -q '^15\.' || {
  echo "not macOS 15 — pick the pkg for this release at macports.org/install.php" >&2
  exit 1
}

# ports that have no prebuilt binary fall back to the system toolchain, so the
# command line tools must be in place first
xcode-select -p >/dev/null 2>&1 || xcode-select --install

cd "$(dirname "$0")"
curl -fLO ${release_base}/v${macports_version}/${pkg}
curl -fLO ${release_base}/v${macports_version}/${chk}

# chk.txt lines look like `SHA256(file)= hash`; flip them into shasum's format
sed -n "s/^SHA256(${pkg})= \(.*\)$/\1  ${pkg}/p" ${chk} | shasum -a 256 --status -c -

sudo installer -pkg ${pkg} -target /

# the pkg runs selfupdate for you; this is the proof it took
/opt/local/bin/port -V
