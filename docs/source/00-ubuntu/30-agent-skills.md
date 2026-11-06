# agent skills

skills are the extension mechanism both agent runtimes use. on this platform they live in three
directories, and knowing which client reads which one is the whole game.

## skill directories

| path | layout | read by | currently holds |
| --- | --- | --- | --- |
| `~/.agents/skills/` | canonical, client-agnostic | qwen-code, opencode, other agent-skills clients | `computer-use`, `find-skills`, `orca-cli`, `orchestration` |
| `~/.qwen/skills/` | symlinks into `~/.agents/skills/` | qwen-code | `find-skills`, `orca-cli`, `orchestration` |
| `~/.claude/skills/` | copies *or* symlinks | claude code | `wiki-read`, `wiki-search`, `wiki-category`, `wiki-edit`, `wiki-plan` |

inspect all three at once:

```bash
ls -l ~/.agents/skills ~/.qwen/skills ~/.claude/skills
```

````{note}
a skill installed only in `~/.claude/skills/` is invisible to qwen-code's skill listing, and vice
versa. when a client does not list a skill you know is installed, the skill is in the other
client's directory — the scripts still run if you call them by path:

```bash
bash ~/.claude/skills/wiki-read/scripts/wiki-read.sh "Main Page"
```
````

## mw-skills

a cross-agent set of MediaWiki skills: read, search, browse categories, edit and plan from wiki
pages.

| | |
| --- | --- |
| source | <https://github.com/brucekomike/mw-skills> |
| local clone | `~/Workspace/om/mw-skills` |
| prerequisites | `curl`, `jq` — both from apt, see [base system](10-base.md) |

### install

```bash
git clone https://github.com/brucekomike/mw-skills.git
cd mw-skills
bash install.sh
```

`install.sh` is idempotent and does five things:

1. creates `~/.agents/skills/`, `~/.claude/skills/` and `~/.config/mw-skills/`
2. removes leftover `~/.claude/commands/{mw-read,mw-search,mw-edit,mw-exec}.md` from older versions
3. removes the renamed `wiki-exec` skill (now `wiki-plan`)
4. for each skill: copies `.agents/skills/<name>` into `~/.agents/skills/<name>`, then replaces
   `~/.claude/skills/<name>` with a symlink to that copy
5. creates `~/.config/mw-skills/config.sh` from the bundled `config.sh.example` with mode `600`,
   but only if it does not exist yet — an existing config is never overwritten

````{warning}
an install that predates step 4 leaves **real directories** in `~/.claude/skills/` and nothing in
`~/.agents/skills/`, so the wiki skills are reachable only by claude code. that is the state this
box is in:

```bash
ls -ld ~/.claude/skills/wiki-read     # drwxrwxr-x — a directory, not a symlink
ls -d ~/.agents/skills/wiki-* 2>/dev/null || echo "(none)"
```

re-running `bash install.sh` converges it: the copies are removed and replaced by symlinks into
`~/.agents/skills/`, which makes the same skills visible to every agent-skills client.
````

### the five skills

| skill | what it does | needs credentials |
| --- | --- | --- |
| `wiki-read` | pages by title prefix, raw wikitext, subpages; `wiki-parse.sh` expands a template or module through the parser | no |
| `wiki-search` | query search, one `title — snippet` line per match | no |
| `wiki-category` | pages in a category, subcategories, intersection, category-name search | no |
| `wiki-edit` | create or replace one page from a local file | **yes** |
| `wiki-plan` | fetch a page and work through it as a procedure, extra arguments are plan parameters | no |

```bash
bash .agents/skills/wiki-read/scripts/wiki-read.sh "Mediawiki" 10
bash .agents/skills/wiki-read/scripts/wiki-parse.sh "Template:Recipe"
bash .agents/skills/wiki-search/scripts/wiki-search.sh "installation guide" 20
bash .agents/skills/wiki-category/scripts/wiki-category.sh "Linux" --subcategories
bash .agents/skills/wiki-category/scripts/wiki-category.sh "Linux" --in "Debian"
bash .agents/skills/wiki-edit/scripts/wiki-edit.sh "My Page" content.txt "edit summary"
```

`wiki-read` fetches prefix matches in batches of 100; the optional limit is the number of page
bodies read (default 5), while the matching-title list stays complete for the batches approved.

### configuration

unconfigured, all skills default to **Wikipedia** (`https://en.wikipedia.org/`). this box points at
a self-hosted wiki instead:

```bash
grep -E '^export MW_(URL|SITE)=' ~/.config/mw-skills/config.sh
```

```text
export MW_URL="https://ossmedia.cn/"
```

resolution order, first match wins:

1. `$MW_SKILLS_CONFIG`
2. `./config.sh`
3. `~/.config/mw-skills/config.sh`

then explicit environment overrides on top of whichever file was found. `MW_SITE=<name>` selects a
named profile built from `MW_SITE_<NAME>_URL` / `_USER` / `_PASS`; `MW_URL`, `MW_USER` and
`MW_PASS` override the selected profile directly. override for a single call without touching the
file:

```bash
MW_URL="https://en.wikipedia.org/" bash .agents/skills/wiki-read/scripts/wiki-read.sh "Main Page"
```

each site gets its own cookie jar — `~/.config/mw-skills/cookies.txt`, mode `600`.

````{warning}
`wiki-edit` authenticates with a MediaWiki **BotPassword** from `Special:BotPassword`. it belongs in
`~/.config/mw-skills/config.sh` (mode `600`, outside any repo) or a secret manager, restricted to
only the rights the bot needs. never commit it, never paste it into a prompt, and for a remote agent
sandbox prefer a small authenticated gateway that keeps the credential on the host.

check the file's mode after any edit:

```bash
stat -c '%a %n' ~/.config/mw-skills/config.sh ~/.config/mw-skills/cookies.txt
```

both should read `600`.
````

`wiki-plan` carries a related risk: the fetched page body is treated as instructions. only run it
against wikis you control and have reviewed.

## orca-installed skills

`computer-use`, `find-skills`, `orca-cli` and `orchestration` in `~/.agents/skills/` come from orca
rather than from a repo you clone; orca keeps its install bookkeeping under
`~/.config/orca/skill-installs/`. treat those four as managed — edit them in orca, not in place.
