# git clis — gh, glab, completions

same trio as the [ubuntu host](../00-ubuntu/40-git-cli.md): **git** moves commits, **gh**
talks to github.com, **glab** talks to gitlab. here all three are ports from the
[port list](20-ports.md) — no vendor apt repos, no standalone installers.

## install

copy-paste from anywhere once macports base is in place:

```bash
sudo port -v install gh glab bash-completion
gh --version | head -1
glab --version | head -1
```

## shell completions

both CLIs generate their own completions; the wiring differs per shell. zsh reads function
files from an `fpath` site-functions dir, bash sources files from `bash-completion.d` — so
the sequence is: append the `compinit` snippet to `~/.zshrc` once, then drop four files in
place (identical logic lives in `src/macos-legacy/shell-completions.sh`):

```bash
grep -q '# macos-legacy completions' ~/.zshrc || cat >> ~/.zshrc <<'EOF'

# macos-legacy completions (shell-completions.sh)
fpath=(/opt/local/share/zsh/site-functions $fpath)
autoload -Uz compinit
compinit
EOF

for tool in gh glab; do
  sudo install -m 0644 <(${tool} completion -s zsh) /opt/local/share/zsh/site-functions/_${tool}
  sudo install -m 0644 <(${tool} completion -s bash) /opt/local/etc/bash_completion.d/${tool}
done
```

re-run it (or paste it again) after every `port upgrade gh glab` — the files are generated
from the installed binary, so they must follow it. one-shot version, same commands plus the
proof checks:

````{literalinclude} ../../../src/macos-legacy/shell-completions.sh
:language: bash
````

## reading it back

open a new shell, then:

```bash
ls /opt/local/share/zsh/site-functions     # _gh and _glab
ls /opt/local/etc/bash_completion.d        # gh and glab
```

proof is a keypress: `gh repo <TAB>` should offer subcommands in both zsh and
`/opt/local/bin/bash`. in bash, plain `/bin/bash` has no completion framework — the macports
`bash` port plus `bash-completion` is what makes it work.

````{note}
`compinit` scans every `fpath` dir on each shell start; if a new shell feels slow to open,
`compinit -C` (skip the audit) is the usual fix in the snippet above.
````

## authentication

logins, credential helpers, host flags, wrappers, aliases — cross-platform and documented
once in [repo access](../20-common/10-repo-access.md). the macos deltas: gh's token lives in
the keychain, glab's helper lines point at `/opt/local/bin/gh` and `/opt/local/bin/glab`, and
the config-file mode check is BSD `stat`:

```bash
stat -f '%Sp %N' ~/.config/glab-cli/config.yml
```
