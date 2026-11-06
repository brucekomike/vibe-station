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

## global variants

`src/macos-legacy/variants.conf` is what gets installed to
`/opt/local/etc/macports/variants.conf`. intel-only and no x11 session is the whole story:

````{literalinclude} ../../../src/macos-legacy/variants.conf
:language: text
````

variants must be in place **before** the first build of a port, otherwise the port is already
installed with the wrong one and `port installed <name>, variants` is how you find out.

## bootstrap

`src/macos-legacy/bootstrap-ports.sh` is the one command that takes a freshly installed macports
base to this station's state:

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
