# repo access — gh and glab setup

how the two hosting CLIs authenticate, which flag picks a host on which subcommand, and the
traps that bite the same way on every machine. installation is platform-specific:
[ubuntu git clis](../00-ubuntu/40-git-cli.md) (apt) or
[macos git clis](../51-macos-legacy/40-git-cli.md) (macports) — everything below is identical
once they are installed.

## authentication

### gh — github.com

```bash
gh auth login
gh auth status
```

```text
github.com
  ✓ Logged in to github.com account brucekomike (keyring)
  - Active account: true
  - Git operations protocol: https
  - Token scopes: 'gist', 'read:org', 'repo', 'workflow'
```

the token lives in the OS credential store — gnome keyring / libsecret on ubuntu, keychain on
macos — not in a dotfile.

````{warning}
`gh auth status` reads the credential store and succeeds **offline** — it proves a token
exists, not that github.com is reachable. before concluding an outage, make a live call:

```bash
gh api user --jq .login
```
````

host selection uses `-R [HOST/]OWNER/REPO` or the `GH_HOST` environment variable. the
`owner/repo@host` suffix form is rejected by the API.

### glab — self-hosted gitlab

one login per instance:

```bash
glab auth login --hostname gitlab.ossmedia.cn
```

tokens are stored in `~/.config/glab-cli/config.yml`, which glab requires to be mode `600`:

```bash
stat -c '%a %n' ~/.config/glab-cli/config.yml   # GNU (ubuntu)
stat -f '%Sp %N' ~/.config/glab-cli/config.yml  # BSD (macos)
glab config get host          # default host, currently gitlab.com
```

hosts configured on the station:

| host | user | git protocol |
| --- | --- | --- |
| `gitlab.com` | — | `ssh` (global default) |
| `gitlab.motewiki.cn` | `brucekomike` | `https` |
| `gitlab.tjaicc.cn` | `root` | `https` |
| `gitlab.ossmedia.cn` | — | — |

also useful in config: `check_update: false` and `glamour_style: dark`.

## git credential helpers

both CLIs register themselves as git credential helpers, which is why https clones and pushes
never prompt. the entries are global and per-host:

```bash
git config --global --get-regexp credential
```

```text
credential.https://github.com.helper
credential.https://github.com.helper !/usr/bin/gh auth git-credential
credential.https://gist.github.com.helper
credential.https://gist.github.com.helper !/usr/bin/gh auth git-credential
credential.https://gitlab.motewiki.cn.helper
credential.https://gitlab.motewiki.cn.helper !/usr/bin/glab auth git-credential
credential.https://gitlab.tjaicc.cn.helper
credential.https://gitlab.tjaicc.cn.helper !/usr/bin/glab auth git-credential
credential.https://gitlab.ossmedia.cn.helper
credential.https://gitlab.ossmedia.cn.helper !/usr/bin/glab auth git-credential
```

the helper paths above are the ubuntu binaries; on the macports station the same lines point
at `/opt/local/bin/gh` and `/opt/local/bin/glab`. each pair is deliberate: the empty value
resets the helper list for that host before the real helper is appended. `.netrc` is not
involved. a host missing from this list will fall back to prompting, so after a new
`glab auth login`, confirm its helper line appeared.

## choosing a host in glab

the flag is **not** uniform across glab subcommands. verified on 1.53.0:

| subcommand | host flag |
| --- | --- |
| `api`, `auth status`, `auth login` | `--hostname <host>` |
| `config get/set/list` | `--host <host>` — `--hostname` is `unknown flag` |
| `token list/create/rotate/revoke` | none — use `-R <host>/owner/repo` |
| `job artifact`, `ci artifact` | `-R` only |
| repo-scoped: `issue`, `mr`, `pipeline`, `ci`, `release` | `-R, --repo [HOST/]OWNER/[NAMESPACE/]REPO` |
| `repo create` | none — pin with `GITLAB_HOST`; the namespace flag is `--group` |
| `repo view`, `repo clone` | none at all — only `GITLAB_HOST` or the config `host:` |

```bash
glab token list --hostname gitlab.com   # unknown flag: --hostname
glab config get host --hostname gitlab.com  # unknown flag: --hostname
glab repo clone --help | grep -c hostname   # 0
```

````{warning}
for repo-scoped commands `GITLAB_HOST` does **not** fall back to the git remote — if it matches
no remote of the current checkout, glab hard-fails:

```text
none of the git remotes configured for this repository correspond to the GITLAB_HOST environment variable
```

`gitlab.com` is special-cased as the built-in default and *does* fall back silently. so setting
a self-managed host as the global `host:` breaks bare `glab mr list` inside checkouts of other
instances.
````

three ways out, in order of preference:

1. pass `-R host/namespace/repo` explicitly
2. set `GITLAB_HOST` to match the checkout's remote
3. pin per-repo in `.git/glab-cli/config.yml` containing `host: <h>` — glab refuses that file
   unless it is mode `600`

`git config glab.host` is ignored, and `-R` rejects a bare remote name or `.`
(`Expected the "[HOST/]OWNER/[NAMESPACE/]REPO" format`).

### clone

`glab repo clone` has no host flag and ignores the host embedded in a full URL, so the env form
is the only reliable one:

```bash
GITLAB_HOST=gitlab.tjaicc.cn glab repo clone supply/ct-push
```

plain `git clone <url>` always works, since glab is not involved.

## shell wrappers per host

`~/.bashrc` defines one wrapper per instance:

```bash
glmw()   { GITLAB_HOST=gitlab.motewiki.cn glab "$@"; }
gloss()  { GITLAB_HOST=gitlab.ossmedia.cn glab "$@"; }
glaicc() { GITLAB_HOST=gitlab.tjaicc.cn   glab "$@"; }
gllif()  { GITLAB_HOST=gitlab.lifclub.cn  glab "$@"; }
```

````{warning}
these are **shell functions, not binaries**. `~/.bashrc` is sourced only by interactive shells,
so a non-interactive `bash -c` — a cron job, a CI step, an agent's tool shell — sees none of
them and `command -v glmw` returns nothing. that is not evidence the wrapper is missing; prove
it with:

```bash
bash -ic 'type glmw'
```

in a non-interactive context, inline the expansion instead:

```bash
GITLAB_HOST=gitlab.motewiki.cn glab mr list
```

`source ~/.bashrc` is not a fix — it returns early behind its own interactivity guard.
````

`gllif` targets `gitlab.lifclub.cn`, which has no entry in `config.yml` yet; it needs
`glab auth login --hostname gitlab.lifclub.cn` before it can authenticate.

## aliases

```bash
glab alias list
```

```text
ci: pipeline ci
co: mr checkout
```

```bash
gh alias list
```

```text
co: pr checkout
```

an alias bakes a **literal command string**, so keep repo paths out of it — host-only aliases
for `api` and `auth` are the useful shape:

```bash
glab alias set osswho 'api user --hostname gitlab.ossmedia.cn'
gh alias set whoami '!gh api user --jq .login'
```

## creating a repo and pushing it

the sequence that works, for github:

```bash
gh repo create vibe-station --public --description "tool chains of the vibe station"
git remote add origin https://github.com/brucekomike/vibe-station.git
git push -u origin main
```

````{note}
add the remote yourself instead of relying on `--source . --push` to wire it. `glab repo
create` has the same habit of leaving the remote unwired, and `glab api` cannot save binary
output to a file — pipe it through `--output` only for text.
````

verify a push by comparing SHAs rather than reading the push output:

```bash
git rev-parse HEAD
gh api repos/brucekomike/vibe-station/commits/main --jq .sha
```

````{warning}
on an unborn branch — a fresh `git init` with no commit yet — `git rev-parse HEAD` prints the
literal string `HEAD` instead of failing. any script that captures it into a variable and
compares silently gets garbage, so commit first, or guard with `git rev-parse --verify HEAD`.
````
