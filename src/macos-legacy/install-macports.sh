#!/bin/bash
# install macports base on the legacy station: intel hardware, macOS 14 sonoma
# or 15 sequoia. run before bootstrap-ports.sh.
set -euo pipefail

macports_version=2.12.7
release_base=https://github.com/macports/macports-base/releases/download

# sequoia is the last release that runs on intel — refuse to install the pkg
# anywhere else
os_major=$(sw_vers -productVersion | cut -d. -f1)
case ${os_major} in
  14) codename=Sonoma ;;
  15) codename=Sequoia ;;
  *)
    echo "not macOS 14 or 15 — pick the pkg for this release at macports.org/install.php" >&2
    exit 1
    ;;
esac
pkg=MacPorts-${macports_version}-${os_major}-${codename}.pkg
chk=MacPorts-${macports_version}.chk.txt

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
