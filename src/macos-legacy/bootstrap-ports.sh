#!/bin/bash
# bring the legacy station's macports tree up to date and install everything in
# ports.txt. re-runnable: `port install` is a no-op for ports already current.
set -euo pipefail
cd "$(dirname "$0")"

test -x /opt/local/bin/port || {
  echo "run install-macports.sh first" >&2
  exit 1
}

sudo port -v selfupdate

# global variant defaults before the first build, so everything takes them.
# no -P: bsd install on macOS does not have it, and the target is a plain file
sudo install -m 0644 variants.conf /opt/local/etc/macports/variants.conf

sudo port -v install $(sed -e 's/#.*//' -e '/^[[:space:]]*$/d' ports.txt | tr '\n' ' ')

# proof: a failed install already aborts the script, so all that is left to
# check is that nothing in the tree is outdated
port outdated
