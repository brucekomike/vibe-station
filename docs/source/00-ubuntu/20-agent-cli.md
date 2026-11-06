# agent clis

two agent runtimes drive the work on this platform: **qwen-code** for in-terminal coding sessions
and **orca** for worktrees, terminals and multi-agent orchestration. neither comes from apt.

## qwen-code

version **0.26.7**, npm package `@qwen-code/qwen-code`, installed by the upstream standalone
installer — not through the distro's nodejs:

```bash
curl -fsSL https://qwen-code-assets.oss-cn-hangzhou.aliyuncs.com/installation/install-qwen-standalone.sh | bash
```

the installer writes a self-contained payload and a wrapper:

| path | role |
| --- | --- |
| `~/.local/lib/qwen-code/` | payload: `bin/`, `lib/`, `node/`, `manifest.json`, `package.json` |
| `~/.local/lib/qwen-code/node/` | bundled node **v22.23.4** |
| `~/.local/bin/qwen` | two-line wrapper that `exec`s `~/.local/lib/qwen-code/bin/qwen` |

```{note}
qwen-code runs on its **own bundled node v22.23.4**, not the apt `nodejs` v24.19.0 from
[base system](10-base.md). upgrading or removing the distro node does not affect it, and a global
`npm install -g` into the distro node is not how this binary is updated — re-run the installer.
```

check what is installed and where it came from:

```bash
qwen --version
cat ~/.local/lib/qwen-code/manifest.json
```

````{tab} output
```text
0.26.7
```
````

````{tab} manifest.json
```json
{
  "name": "@qwen-code/qwen-code",
  "version": "0.26.7",
  "target": "linux-x64",
  "runtime": "node",
  "nodeArchive": "node-v22.23.4-linux-x64.tar.xz",
  "createdAt": "2026-11-04T03:58:54.659Z"
}
```
````

### state layout

everything qwen-code persists lives under `~/.qwen/`:

| path | scope |
| --- | --- |
| `~/.qwen/settings.json` | global settings — `ui`, `env`, `modelProviders`, `security`, `model`, `providerMetadata`, `hooks` |
| `~/.qwen/memories/` | cross-project auto-memory, with its own `MEMORY.md` index |
| `~/.qwen/skills/` | symlinks into `~/.agents/skills/`, see [agent skills](30-agent-skills.md) |
| `~/.qwen/projects/<project-hash>/memory` | per-project memory, keyed to the exact working directory |

the per-project directory is keyed to the literal `pwd`, so running qwen-code from `~/Workspace`
and from `~/Workspace/om/om-docs` gives two different project memories.

## orca

version **1.4.244**, distributed as an appimage whose payload is unpacked under `~/.cache/orca`.
there is no apt package and no manual download step to reproduce — the desktop app manages the
payload and registers the cli.

the call chain is three hops:

```text
orca  /  orca-ide                     <- what you type
  -> ~/.cache/orca/appimage/launcher/orca-ide      <- stable launcher, waits up to 5s
       -> ~/.cache/orca/appimage/launcher/installed <- symlink, repointed on every update
            -> ~/.cache/orca/appimage/<install-id>/<hash>/resources/bin/orca-ide
```

the launcher exists so that the path you type never changes across updates, and so a call racing
an in-progress update waits instead of failing:

```bash
cat ~/.cache/orca/appimage/launcher/orca-ide
ls -l ~/.cache/orca/appimage/launcher/installed
```

if the payload is missing, the launcher prints
`Orca CLI is not ready; reopen Orca or register the CLI again.` rather than a shell error.

### two entry points

| command | resolves to | available in |
| --- | --- | --- |
| `orca` | `~/.config/orca/linux-orca-cli-shim/orca` | shells spawned by the orca app, which prepends the shim directory to `PATH` |
| `orca-ide` | `~/.local/bin/orca-ide` → the same launcher | every shell, because `~/.local/bin` is on `PATH` |

````{warning}
`orca` is also the name of the **GNOME screen reader**, which *is* an apt package on this box. in a
plain login shell — one not spawned by the orca app — the shim directory is not on `PATH`, so
`orca` resolves to `/usr/bin/orca` and answers a completely different version:

```bash
env -i HOME="$HOME" bash -lc 'command -v orca; orca --version'
```

```text
/usr/bin/orca
Orca version 51.0, AT-SPI2 version: 2.62.0, Session: wayland KDE
```

use `orca-ide` in scripts, cron jobs and anything not launched from inside orca. check which one you
got with `command -v orca` before trusting the output.
````

### state layout

| path | role |
| --- | --- |
| `~/.config/orca/orchestration.db` | worktrees, tasks, agent sessions |
| `~/.config/orca/agent-session-journal.db` | session journal, with `-shm` / `-wal` sidecars |
| `~/.config/orca/logs/` | runtime logs — first place to look when a worktree or terminal misbehaves |
| `~/.config/orca/profiles/`, `orca-profile-index.json` | per-profile state |
| `~/.config/orca/skill-installs/` | skill install bookkeeping |
| `~/.config/orca/terminal-history/` | captured terminal output |

## verifying both

```bash
qwen --version; orca-ide --version; command -v orca
```

expected: `0.26.7`, `1.4.244`, and a path that is either the shim directory or `/usr/bin/orca`.
