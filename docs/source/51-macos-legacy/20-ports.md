# port list

one manifest, one variants file, one bootstrap script — all in
`src/macos-legacy/`, all included into this page verbatim so the documentation and the machine
setup are the same file.

## the list

`src/macos-legacy/ports.txt` is the set of ports this station insists on:

````{literalinclude} ../../../src/macos-legacy/ports.txt
:language: text
````

add a port by adding a line here and re-running the bootstrap — not by installing ad hoc on the
machine and hoping the page gets updated.

the whole list installs in one line from the repo root, comments and blank lines stripped:

```bash
sudo port -v install $(grep -vE '^[[:space:]]*(#|$)' src/macos-legacy/ports.txt)
```

this skips `selfupdate` and the variants step, so run the full bootstrap sequence (below) for a
first-time setup and this one-liner for a quick top-up.

## global variants

`src/macos-legacy/variants.conf` is what gets installed to
`/opt/local/etc/macports/variants.conf`. intel-only and no x11 session is the whole story:

````{literalinclude} ../../../src/macos-legacy/variants.conf
:language: text
````

variants must be in place **before** the first build of a port, otherwise the port is already
installed with the wrong one and `port installed <name>, variants` is how you find out.

## bootstrap

the whole sequence, copy-paste ready from the repo root — paste it straight into a terminal, no
script file needed:

```bash
sudo port -v selfupdate
sudo install -m 0644 src/macos-legacy/variants.conf /opt/local/etc/macports/variants.conf
sudo port -v install $(grep -vE '^[[:space:]]*(#|$)' src/macos-legacy/ports.txt)
port outdated
```

`src/macos-legacy/bootstrap-ports.sh` wraps the same commands for one-shot execution:

````{literalinclude} ../../../src/macos-legacy/bootstrap-ports.sh
:language: bash
````

re-runnable by design: `port install` skips anything already current, so the script doubles as
the weekly update pass.

## reading it back

```bash
port installed                       # everything macports put on this box
port outdated                        # must print nothing after a bootstrap
port info --path git                 # where a port's own build recipe lives
```

````{note}
`sudo port uninstall inactive` cleans up leftovers after upgrades. run it only once
`port outdated` is empty — on a legacy intel box a rebuild is slower than on current hardware,
and you want the list settled before removing the old revisions still being used.
````
