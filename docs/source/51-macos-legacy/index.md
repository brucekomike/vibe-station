# macos legacy — intel, macos 14 and 15, macports

one machine: an intel mac held at **macOS 14 sonoma** or **macOS 15 sequoia**, sequoia being the
last release that boots intel hardware. 14 and 15 are the ceiling for this box, which is why the
section is named *legacy* — the chain is about keeping an aging station useful, not about tracking
the newest macOS.

everything third-party is installed through **macports**, one prefix (`/opt/local`), one port
tree, no homebrew, no vendor installers except the macports pkg itself. the scripts that do the
work live in `src/macos-legacy/` at the repo root; every code block below is included straight
from those files with `{literalinclude}`, so the page and the script cannot drift apart.

## at a glance

| layer | tool | version | installed from | page |
| --- | --- | --- | --- | --- |
| base | macos | 14.x sonoma / 15.x sequoia | software update | [base system](10-base.md) |
| base | xcode command line tools | 15.x / 16.x | `xcode-select --install` | [base system](10-base.md) |
| base | macports | 2.12.7 | upstream pkg | [base system](10-base.md) |
| ports | git, rsync, tmux, … | `port installed` | macports | [port list](20-ports.md) |
| ports | python312, nodejs22 | `port installed` | macports | [port list](20-ports.md) |
| ports | gh, glab + zsh/bash completions | `port installed` | macports | [git clis](40-git-cli.md) |
| docs | sphinx + furo | pip into `~/.venv` | macports python | [docs build chain](30-docs-build.md) |

## re-reading the whole table

```bash
sw_vers; uname -m            # x86_64 is the whole point of this section
xcode-select -p
/opt/local/bin/port -V
/opt/local/bin/port installed
python3.12 --version
~/.venv/bin/sphinx-build --version
```

port versions are read from `port installed` rather than repeated here — the tree updates weekly
and a hand-copied table would be wrong by Friday.

```{toctree}
:hidden:
:maxdepth: 2
10-base
20-ports
30-docs-build
40-git-cli
```
