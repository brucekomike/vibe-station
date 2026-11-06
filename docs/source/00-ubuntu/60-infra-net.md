# infra and network

containers, one hashicorp binary, the proxy wrapper the rest of the chain depends on, and the ssh
setup used to reach every other host.

## docker

ubuntu's own package, **not** `docker-ce` from a vendor repository:

```bash
sudo apt install docker.io docker-compose-v2
sudo usermod -aG docker "$USER"
```

| component | version | package |
| --- | --- | --- |
| `docker` | 29.7.2 | `docker.io` (`29.7.2-0ubuntu1`) |
| `docker compose` | 2.40.3 | plugin, `2.40.3+ds2-0ubuntu2` |

there is no legacy `docker-compose` binary — the subcommand form is the only one.

`docker` group membership is what removes the `sudo` from every docker call; it applies at the next
login, or immediately with `newgrp docker`. verify:

```bash
docker --version; docker compose version; id -nG | tr ' ' '\n' | grep -x docker
```

### daemon proxy

image pulls go through the local proxy via a systemd drop-in. the file is root-owned, so stage it in
the user tree and hand the install over as one command — see
[base system](10-base.md) on interactive sudo.

`/etc/systemd/system/docker.service.d/proxy.conf`:

```ini
[Service]
Environment="HTTP_PROXY=http://127.0.0.1:7897/"
Environment="HTTPS_PROXY=http://127.0.0.1:7897/"
Environment="NO_PROXY=localhost,127.0.0.1,.example.com"
```

```bash
sudo systemctl daemon-reload && sudo systemctl restart docker
docker info | grep -i proxy
```

```text
 HTTP Proxy: http://127.0.0.1:7897/
 HTTPS Proxy: http://127.0.0.1:7897/
 No Proxy: localhost,127.0.0.1,.example.com
```

````{note}
`.example.com` in `NO_PROXY` is a placeholder. replace it with the internal registry and LAN domains
that must be reached directly, otherwise the daemon sends LAN traffic to the proxy too. this drop-in
configures the **daemon** — pulls. what a running container sees comes from the client's environment
or `~/.docker/config.json`, not from here.
````

the proxy endpoint is the local mihomo listener:

```bash
ss -ltnp | grep 7897
```

```text
LISTEN 0 4096 *:7897 *:* users:(("verge-mihomo",pid=8481,fd=8))
```

if that line is empty, mihomo is not running and every proxied command — docker pulls included —
will time out rather than fail fast.

## terraform

version **1.16.6**, installed as a standalone binary; no package owns it:

```bash
dpkg -S ~/.local/bin/terraform
```

```text
dpkg-query: no path found matching pattern /home/brucekomike/.local/bin/terraform
```

| | |
| --- | --- |
| path | `~/.local/bin/terraform` |
| size | 115 MB |
| source | upstream release archive from `releases.hashicorp.com` |

upgrade by downloading the new archive and replacing the binary in place — `~/.local/bin` is already
on `PATH`, so nothing else changes:

```bash
terraform --version
```

```text
Terraform v1.16.6
on linux_amd64
```

## proxy.sh

a four-line wrapper that exports proxy variables for **one command** and then execs it. it lives at
`/usr/local/bin/proxy.sh`, mode `755`, owner `root:root` — so installing or editing it needs sudo.

```bash
#!/bin/bash
PROXYSH_PORT=${TEMP_PORT:-7897}  # Use TEMP_PORT if provided, otherwise default to 7897
export ProIP="http://127.0.0.1:$PROXYSH_PORT"
export http_proxy="$ProIP"
export https_proxy="$ProIP"
export NO_PROXY="localhost,127.0.0.1,192.168.*"

# Execute the command passed as arguments
"$@"
```

prefix any network command with it:

```bash
proxy.sh gh api user --jq .login
proxy.sh git push -u origin main
proxy.sh pip install -r docs/requirements.txt
TEMP_PORT=7890 proxy.sh curl -sS https://example.com
```

what the child process actually sees:

```bash
proxy.sh env | grep -iE '^(http_proxy|https_proxy|NO_PROXY|ProIP)='
```

```text
https_proxy=http://127.0.0.1:7897
NO_PROXY=localhost,127.0.0.1,192.168.*
http_proxy=http://127.0.0.1:7897
ProIP=http://127.0.0.1:7897
```

````{note}
two consequences of the `"$@"` shape. the exports die with the child, so `proxy.sh export FOO=bar`
changes nothing in your shell — and a command that spawns its own children (make, pip, npm) passes
the proxy down correctly, which is exactly why the wrapper is used instead of exporting once.
`NO_PROXY` covers `192.168.*`, so LAN hosts and self-hosted gitlab instances inside that range stay
direct.
````

## ssh and rsync

`openssh-client` and `rsync` from apt. rsync is the upload half of `bin/build-docs.sh`, see
[docs build chain](50-docs-build.md).

### config layout

| path | contents |
| --- | --- |
| `~/.ssh/config` | `Include ~/.ssh/config.d/*` plus the `Host *` and LAN defaults below |
| `~/.ssh/config.d/` | `appleinsky`, `devices`, `lifclub`, `mainland`, `mine`, `nas`, `NI`, `probe`, `tjut`, `yaogal` |
| `~/.ssh/keys/` | key groups: `com`, `mine`, `probe`, `tjaicc`, `tjut` |
| `/etc/ssh/ssh_config.d/` | system-wide aliases: `20-systemd-ssh-proxy.conf`, `50-509.conf` |

config file names and key groups do **not** line up — `config.d/nas` and `config.d/probe` point at
keys under `keys/mine/`.

````{warning}
`~/.ssh/config.d` is not the whole picture: `/etc/ssh/ssh_config` includes
`/etc/ssh/ssh_config.d/*.conf`, and those define real aliases that appear nowhere in the user
directory. `50-509.conf` carries `Host lif-ct-*` → `User root`, `IdentityFile /opt/keys/lif`, with
per-host `Hostname` lines. grepping only the user directory and concluding an alias does not exist is
the easy mistake. resolve first:

```bash
ssh -G lif-ct-gentoo | grep -iE '^(hostname|user|identityfile) '
```

```text
user root
hostname 192.168.24.50
identityfile /opt/keys/lif
```
````

### the Host * defaults

```text
Host *
  RemoteForward 12321 127.0.0.1:7890
  ServerAliveInterval 120
  TCPKeepAlive yes
  ServerAliveCountMax 3
  IdentitiesOnly yes
  AddKeysToAgent yes
```

````{warning}
`RemoteForward 12321 127.0.0.1:7890` applies to **every** connection, so a loopback `:12321`
listener found on any host you ssh into is this laptop's tunnel, not a service running there. check
this file before naming an unexplained listener.
````

and the LAN block:

```text
Host 192.168.*.* 100.64.*.* 10.*.*.*
  StrictHostKeyChecking no
  UserKnownHostsFile /dev/null
```

LAN connections never verify a host key, so a successful login there is not evidence of pinning. both
blocks vanish under `ssh -F <profile>`, which skips the user config entirely — the way to test
behaviour an alias never exercises.

### when several hosts time out at once

````{warning}
the group keys are passphrase-protected, so with an empty agent every `ProxyJump` alias prompts and
then dies with `Connection timed out during banner exchange` or
`Connection to UNKNOWN port 65535 timed out`. four hosts failing simultaneously reads like a
cluster-wide outage and is usually client-side auth:

```bash
ssh-add -l
```

```text
The agent has no identities
```

run that **before** concluding anything about the remote machines. `ssh -G` resolves fully with an
empty agent — it proves config, never reachability.
````

## node and npm

| | version | from |
| --- | --- | --- |
| `node` | v24.19.0 | apt `nodejs` |
| `npm` | 11.16.0 | with `nodejs` |

````{note}
qwen-code does **not** use this node — it runs on the v22.23.4 bundled inside
`~/.local/lib/qwen-code/node/`. a global `npm install -g` into the distro node therefore has no
effect on the `qwen` binary. see [agent clis](20-agent-cli.md).
````
