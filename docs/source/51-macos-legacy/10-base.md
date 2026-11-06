# base system

intel hardware running **macOS 15 sequoia** — the last macOS release with intel support. the base
layer is apple's own command line tools plus one installer: the macports pkg. after that, nothing
lands on this machine except through `port`.

## check the machine is what this section claims

```bash
sw_vers -productVersion
uname -m
```

```text
15.7.2
x86_64
```

`uname -m` must print `x86_64`. sequoia is a universal build, so an apple silicon box answers
`arm64` and wants the same pkg name — but none of the *legacy* caveats in this section apply
there.

## xcode command line tools

macports shells out to apple's clang, make and ld whenever a port has no prebuilt binary for the
release. sequoia wants command line tools **16.0 or later**:

```bash
xcode-select -p
```

```text
/Library/Developer/CommandLineTools
```

if the path is missing, install them:

```bash
xcode-select --install
```

## installing macports

the sequoia installer is `MacPorts-<version>-15-Sequoia.pkg` at the
[macports releases](https://github.com/macports/macports-base/releases) — one universal pkg for
both intel and apple silicon. the pinned version and the checksum handling live in a script at
`src/macos-legacy/install-macports.sh`, included here verbatim:

````{literalinclude} ../../../src/macos-legacy/install-macports.sh
:language: bash
````

run it from anywhere; it fetches the pkg next to itself, verifies the `SHA256` line in the release
checksums file, and hands the pkg to `installer`. sudo is interactive on this box — the same rule
as the [ubuntu station](../00-ubuntu/10-base.md): stage as user, escalate once.

## what the pkg leaves behind

| path | what lives there |
| --- | --- |
| `/opt/local/bin`, `/opt/local/sbin` | every macports-provided command |
| `/opt/local/etc/macports/macports.conf` | macports configuration |
| `/opt/local/etc/macports/variants.conf` | global variant defaults, see [port list](20-ports.md) |
| `/opt/local/var/macports/` | the ports tree, receipts, and build logs |

the installer prepends `/opt/local/bin` and `/opt/local/sbin` to `PATH` in the shell profile
files. open a new shell, then prove the precedence is right:

```bash
command -v port; port -V
```

## keeping base current

```bash
sudo port -v selfupdate
```

`selfupdate` syncs the ports tree and rebuilds macports base itself when a new release is out —
it is how the station moves from e.g. 2.12.5 to 2.12.7 without touching the pkg again. run it
before every port install session; [bootstrap-ports.sh](20-ports.md) does it for you.

````{note}
if the box ever gets upgraded between major macOS releases (it should not — sequoia is the intel
ceiling), the old `/opt/local` builds link against stale system frameworks. the fix is
`sudo port migrate` after installing the new command line tools, or a fresh pkg plus a re-run of
the scripts in this section.
````
