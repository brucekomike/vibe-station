# ubuntu

the tool chain of the ubuntu platform: one amd64 laptop running **ubuntu 26.10**, used as the
authoring host, the agent host and the build host for the documentation and container work.

the chain is deliberately thin — distro packages for everything that has a good ubuntu archive
entry, and three user-writable locations for everything else:

| location | holds |
| --- | --- |
| `~/.local/bin` | wrappers and loose binaries: `qwen`, `orca-ide`, `terraform` |
| `~/.venv` | the sphinx + furo documentation toolchain |
| `~/.cache/orca` | the orca appimage payload reached through the launcher |

## at a glance

versions below were read off the machine on **2026-11-06**.

| layer | tool | version | installed from | page |
| --- | --- | --- | --- | --- |
| base | ubuntu | 26.10 | — | [base system](10-base.md) |
| base | git | 2.55.0 | apt | [base system](10-base.md) |
| base | python3 | 3.14.8 | apt | [base system](10-base.md) |
| agent | qwen-code | 0.26.7 | standalone installer | [agent clis](20-agent-cli.md) |
| agent | orca | 1.4.244 | appimage | [agent clis](20-agent-cli.md) |
| skills | mw-skills | git `main` | `install.sh` | [agent skills](30-agent-skills.md) |
| git | gh | 2.102.0 | apt | [git clis](40-git-cli.md) |
| git | glab | 1.53.0 | apt | [git clis](40-git-cli.md) |
| docs | sphinx | 9.1.1 | pip into `~/.venv` | [docs build chain](50-docs-build.md) |
| docs | furo | 2025.12.19 | pip into `~/.venv` | [docs build chain](50-docs-build.md) |
| infra | docker | 29.7.2 | apt (`docker.io`) | [infra and network](60-infra-net.md) |
| infra | terraform | 1.16.6 | upstream binary | [infra and network](60-infra-net.md) |
| network | proxy.sh | — | hand-written, `/usr/local/bin` | [infra and network](60-infra-net.md) |

## re-reading the whole table

one pass that prints the versions this section claims:

```bash
lsb_release -ds
git --version; python3 --version; node --version; npm --version
qwen --version; orca --version
gh --version | head -1; glab --version | head -1
~/.venv/bin/sphinx-build --version
docker --version; terraform --version | head -1
```

anything that prints nothing is not on `PATH` — see [base system](10-base.md) for where the
wrappers live.

```{toctree}
:hidden:
:maxdepth: 2
10-base
20-agent-cli
30-agent-skills
40-git-cli
50-docs-build
60-infra-net
```
