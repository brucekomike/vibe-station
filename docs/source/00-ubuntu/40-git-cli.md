# git clis

three tools, three jobs: **git** moves commits, **gh** talks to github.com, **glab** talks to
self-hosted gitlab instances. all three come from the ubuntu archive on 26.10 — see
[base system](10-base.md).

```bash
sudo apt install git gh glab
```

| tool | version | package |
| --- | --- | --- |
| `git` | 2.55.0 | `1:2.55.0-1ubuntu1.1` |
| `gh` | 2.102.0 | `gh` |
| `glab` | 1.53.0 | `glab` (`1.53.0-1build1`) |

## setup and quirks

everything after installation — `gh auth login`, per-instance `glab auth login`, credential
helper lines, glab host flags, per-host wrappers, aliases, repo-create traps — is the same on
every machine and lives in [repo access](../20-common/10-repo-access.md).

## network path

github.com is reachable both directly and through the local proxy. `proxy.sh` sets
`NO_PROXY=localhost,127.0.0.1,192.168.*`, so a gitlab instance resolving into the `192.168.*`
range bypasses the proxy automatically — see [infra and network](60-infra-net.md).
