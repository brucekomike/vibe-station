# base system

ubuntu **26.10**, amd64. everything else in this section is either a distro package or a file
inside the user's home directory — there is no vendor apt repository on this box.

## check the release

```bash
lsb_release -ds
```

```text
Ubuntu 26.10
```

## the apt layer

update first, then install the packages the rest of the chain depends on:

```bash
sudo apt update && sudo apt upgrade
sudo apt install build-essential python3-venv git curl jq rsync openssh-client
```

what each one provides, with the versions currently installed:

| package | version | provides |
| --- | --- | --- |
| `git` | `1:2.55.0-1ubuntu1.1` | version control for every repo under `~/Workspace` |
| `curl` | `8.20.0-2ubuntu11.1` | installer downloads, mediawiki api calls |
| `jq` | `1.8.2-1ubuntu1` | json handling in scripts and skills |
| `build-essential` | `12.12ubuntu5` | gcc 15.3.0, make 4.4.1 — needed to compile pip wheels |
| `python3-venv` | `3.14.7-3` | the `venv` module for python 3.14.8 |
| `nodejs` | `24.19.0+dfsg+~cs24.13.3-1ubuntu1` | node v24.19.0 and npm 11.16.0 |
| `rsync` | — | the upload half of `bin/build-docs.sh` |
| `gh` | `2.102.0` | see [git clis](40-git-cli.md) |
| `glab` | `1.53.0-1build1` | see [git clis](40-git-cli.md) |
| `docker.io` | `29.7.2-0ubuntu1` | see [infra and network](60-infra-net.md) |

````{note}
`gh` and `glab` come straight from the ubuntu archive on 26.10 — no `cli.github.com` keyring, no
vendor `.list` file. `/etc/apt/sources.list.d/` holds only `ubuntu.sources`. confirm where a binary
came from with `dpkg -S`:

```bash
dpkg -S /usr/bin/gh /usr/bin/glab
```
````

## sudo is interactive

there is no passwordless sudo here, so `sudo -n true` fails:

```bash
sudo -n true; echo "exit=$?"
```

```text
sudo: a password is required
exit=1
```

practical consequence: anything that must land in a root-owned path — `/usr/local/bin/proxy.sh`,
`/etc/systemd/system/docker.service.d/proxy.conf` — gets staged in the user tree first, then
handed over as a single `sudo install` / `sudo cp` command rather than edited in place.

## user-writable locations

| path | what lives there |
| --- | --- |
| `~/.local/bin` | `qwen` wrapper, `orca-ide` symlink, `terraform`, `adb`, `fastboot` |
| `~/.local/lib/qwen-code` | the qwen-code payload plus its own bundled node runtime |
| `~/.venv` | sphinx + furo toolchain, created with `--system-site-packages` |
| `~/.cache/orca` | orca appimage payload |
| `~/.agents/skills` | canonical agent skills, shared across agent clients |
| `~/.config/{qwen,orca,glab-cli,mw-skills}` | per-tool state and configuration |

`~/.local/bin` is on `PATH` from both `~/.profile` and `~/.bashrc`:

```bash
grep -n 'local/bin' ~/.profile ~/.bashrc
```

so a new wrapper dropped in there is available in the next shell with no extra setup. confirm the
effective order with:

```bash
command -v qwen orca-ide terraform
```

## groups

```bash
groups
```

```text
brucekomike adm dialout cdrom sudo audio dip plugdev users lxd docker lpadmin
```

`docker` and `lxd` are what let container commands run without `sudo`. group membership only
applies to a new login session; `newgrp docker` grants it to the current shell immediately.
