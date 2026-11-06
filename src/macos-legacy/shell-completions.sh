#!/bin/bash
# wire gh and glab completions into the station's two shells: zsh reads the
# site-functions dir off fpath, bash sources bash-completion.d on startup.
# re-runnable — it overwrites what it installed, run it again after upgrades.
set -euo pipefail

# zsh only sees the functions if compinit scans the macports directory; the
# marker keeps the snippet from duplicating on re-runs
grep -q '# macos-legacy completions' ~/.zshrc 2>/dev/null || cat >> ~/.zshrc <<'EOF'

# macos-legacy completions (shell-completions.sh)
fpath=(/opt/local/share/zsh/site-functions $fpath)
autoload -Uz compinit
compinit
EOF

for tool in gh glab; do
  # the CLIs generate their own completions; one file per shell
  sudo install -m 0644 <(${tool} completion -s zsh) \
    /opt/local/share/zsh/site-functions/_${tool}
  sudo install -m 0644 <(${tool} completion -s bash) \
    /opt/local/etc/bash_completion.d/${tool}
done

# proof: all four files present and non-empty
test -s /opt/local/share/zsh/site-functions/_gh
test -s /opt/local/share/zsh/site-functions/_glab
test -s /opt/local/etc/bash_completion.d/gh
test -s /opt/local/etc/bash_completion.d/glab
