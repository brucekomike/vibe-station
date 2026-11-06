# docs build chain

this station builds the same sphinx + furo sites as the
[ubuntu host](../00-ubuntu/50-docs-build.md) — only the python differs. on macports, python is a
port, not an apt package, and the venv hangs off macports' `python3.12`.

## the layer

| component | provider | role |
| --- | --- | --- |
| `python312` | macports | the interpreter behind `python3.12` |
| `py312-virtualenv` | macports | creates `~/.venv` |
| `pip` | inside the venv | installs `docs/requirements.txt` |
| apple clang | command line tools | compiles wheels with c extensions |

## setup

`src/macos-legacy/docs-chain.sh`, run from the repo root:

````{literalinclude} ../../../src/macos-legacy/docs-chain.sh
:language: bash
````

the `--system-site-packages` flag keeps macports-installed python packages visible inside the
venv, which is what the ubuntu chain does too — same `bin/venv.sh` semantics, different base
interpreter.

## build

```bash
source ~/.venv/bin/activate
make -C docs html
```

live reload with `bin/live-docs.sh`, exactly like every other site on the station.

````{note}
if `pip` starts failing to compile a wheel, it is almost never the wheel's fault on this box —
it is the command line tools being older than the port tree expects. check with
`xcode-select -p` and `clang --version`, then re-install the tools; the compiler is apple's, not
`/opt/local`'s.
````

## git over macports

`git` comes from the port list, so the clone side of the docs chain is identical to ubuntu:

```bash
git --version
command -v git        # /opt/local/bin/git — macports wins over the apple shim
```

the apple command line tools still ship their own git; a `/usr/bin/git` on `PATH` means the
profile edit described in [base system](10-base.md) did not take.
