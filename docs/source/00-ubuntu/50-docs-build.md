# docs build chain

every documentation site on this platform — including this one — is sphinx with the furo theme,
built from the [furo-embeded](https://github.com/brucekomike/furo-embeded) template. the chain is
python from apt, packages from pip into a venv, `make html` for output, and CI for publishing.

## python layer

| component | version | from |
| --- | --- | --- |
| `python3` | 3.14.8 | apt |
| `python3-venv` | 3.14.7-3 | apt |
| `build-essential` | 12.12ubuntu5 | apt — gcc 15.3.0, make 4.4.1, needed to compile wheels |
| `pip` | 26.1.2 | inside the venv |

## venv

two patterns are in use and both are fine:

````{tab} shared venv
one `~/.venv` for every docs project, created with `--system-site-packages` so distro packages stay
visible. `bin/venv.sh` creates it if needed and drops you into a subshell with it activated:

```bash
bin/venv.sh
```

```bash
python3 -m venv ~/.venv --system-site-packages   # what it runs
source ~/.venv/bin/activate                      # or activate by hand
pip install -r docs/requirements.txt
```
````

````{tab} per-project venv
a `.venv` next to the project, for sites that must pin different versions. the template's
`.gitignore` already covers it (`**/.venv`), so nothing leaks into the repo:

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r docs/requirements.txt
```
````

confirm which interpreter you are about to build with:

```bash
command -v sphinx-build; sphinx-build --version
```

## packages

`docs/requirements.txt`, unpinned — every install takes the current release:

```text
furo
sphinx
myst-parser
myst-parser[linkify]
sphinx-inline-tabs
sphinxext-opengraph
sphinx-copybutton
sphinx-autobuild
sphinx-design
sphinxcontrib-mermaid
```

versions verified in `~/.venv` on 2026-11-06:

| package | version | role |
| --- | --- | --- |
| `sphinx` | 9.1.1 | builder |
| `furo` | 2025.12.19 | theme |
| `sphinx-basic-ng` | 1.0.0b2 | furo's base theme — where the `source_repository` parsing lives |
| `myst-parser` | 5.1.0 | markdown source |
| `sphinx-design` | 0.7.0 | grids, cards, dropdowns |
| `sphinx-inline-tabs` | 2025.12.21.14 | the `{tab}` directive |
| `sphinx-copybutton` | 0.5.2 | copy button on code blocks |
| `sphinxext-opengraph` | 0.13.0 | `ogp_*` social metadata |
| `sphinx-autobuild` | 2025.8.25 | live reload |
| `sphinxcontrib-mermaid` | 2.1.1 | installed but **not enabled** by default |

list what a venv actually has:

```bash
pip list | grep -Ei 'sphinx|furo|myst'
```

## build

```bash
make -C docs html          # output: docs/build/html
```

`docs/build` is gitignored (`**/build`). for a from-scratch rebuild that ignores the cached
environment and rewrites every page:

```bash
make -C docs html SPHINXOPTS="-aE"
```

live reload, which offers that purge when a previous build exists:

```bash
bin/live-docs.sh           # serves docs/build/html
```

treat warnings as failures — an orphaned page or a bad link shows up here, not in the rendered
output:

```bash
make -C docs html SPHINXOPTS="-W --keep-going"
```

## packaging and remote deploy

`bin/build-docs.sh` builds, renames the output to a stable directory name, tarballs it into
`archives/` and optionally ships it to a web root:

```bash
bin/build-docs.sh vibe-station                 # build + archive only
bin/build-docs.sh vibe-station user@host       # ...then rsync and extract remotely
```

the remote path is hard-coded to `/opt/www/docs/`, and the script runs `sudo mkdir` / `sudo chown`
over ssh there, so the remote account needs sudo. `bin/archive.sh <name>` archives the git tree
instead of the build output:

```bash
bin/archive.sh vibe-station        # archives/vibe-station.tar.gz from git archive HEAD
```

## publishing

### github pages

`.github/workflows/build.yml` builds and deploys on every push to `main` that touches `docs/**`:

| step | detail |
| --- | --- |
| runner | `ubuntu-latest`, python `3.12` |
| build | `pip install -r requirements.txt`, then `make html` in `docs/` |
| artifact | `docs/build/html` via `actions/upload-pages-artifact@v3` |
| deploy | `actions/deploy-pages@v5`, job environment `github-pages` |
| permissions | `contents: read`, `pages: write`, `id-token: write` |
| concurrency | group `pages`, `cancel-in-progress: false` |

the site lands at `https://<user>.github.io/<repo>/`, which is what `ogp_site_url` in `conf.py` must
match. the older gh-pages-branch method is still in the file, commented out.

### gitlab pages / self-hosted runner

`.gitlab-ci.yml` targets a self-hosted runner tagged `ubuntu 24.04` + `shared`, builds the same way
and publishes `html-docs` as a job artifact expiring after one week:

```yaml
before_script:
  - python3 -m venv .venv
  - source .venv/bin/activate
  - pip install -r docs/requirements.txt
script:
  - cd docs && make html && mv build/html ../html-docs
```

the runner needs `build-essential` and `python3-venv` installed on the host.

````{note}
furo's *view this page* / *edit this page* links are built by
`sphinx_basic_ng/theme/basic-ng/components/{edit,view}-this-page.html`, which only pattern-matches
`github.com`, `gitlab.com` and `bitbucket.org`. any other host falls through to a warning printed
**twice per page**:

```text
Could not understand `source_repository` provided
```

on github, `source_repository` + `source_branch` + `source_directory` is enough. on a self-managed
gitlab, set both explicit links, each with the `/-/` path segment and the `{filename}` placeholder —
the two macros are independent, so setting only one still warns:

```python
"source_edit_link": "https://<host>/<owner>/<repo>/-/edit/main/docs/source/{filename}",
"source_view_link": "https://<host>/<owner>/<repo>/-/blob/main/docs/source/{filename}",
```
````

## starting a new site from the template

the template is consumed **by copy**, not as a submodule — every derived site owns its files:

```bash
mkdir -p <new-project>
git -C ~/Workspace/om/furo-embeded archive HEAD | tar -x -C <new-project>
cd <new-project> && git init -b main
```

`git archive HEAD` rather than `cp -a` keeps the copy free of `.git`, build output and archives. then
the five edits:

1. `docs/source/conf.py` — inside the `## change required >>> ... <<<` blocks: `project`,
   `copyright`, `release`, `language`, `html_title`, `source_repository`, `ogp_site_url`,
   `ogp_site_name`, `highlight_language`
2. `README.md` — the text between `<!-- start elevator-pitch -->` and `<!-- end elevator-pitch -->`;
   `index.md` includes exactly that range onto the front page
3. `docs/source/index.md` — replace the example `toctree` entries with the real sections
4. `docs/source/_templates/page.html` — the two footer links
5. delete the template's own example content: `docs/source/00-manual/`, `01-reference/`,
   `zz-editing/`

## house conventions

- a top-level section is `NN-name/` with an `index.md`; pages inside are `NN-slug.md`, tens apart so
  pages can be inserted later without renumbering
- `bin/new-section.sh 01-gentoo` scaffolds that shape
- every page must be reachable from a `toctree` — an unwired page warns as orphaned
- `highlight_language` is `bash`, so a bare fence highlights as shell; command output belongs in a
  fence explicitly tagged `text`
- when a directive contains a code fence, the outer fence needs more backticks than anything inside
  it — four for the directive, three for the code:

````{tab} right
`````text
````{note}
prose

```bash
some-command
```
````
`````
````

````{tab} wrong
`````text
```{note}
prose

```bash
some-command      <- this fence closes the note early
```
`````
````

- `sphinx-design` 0.7.0 has no `link-card`; inside a `{grid}`, children must be `{grid-item-card}`
