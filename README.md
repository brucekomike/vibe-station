<!-- start elevator-pitch -->
# vibe-station
the tool chains this station runs on — what is installed, where it lives, how it got there
and how to prove it still works.

one section per platform. currently documented: **ubuntu** and the intel
**macos 15 / macports** legacy station.
<!-- end elevator-pitch -->

## layout

- `docs/source/00-ubuntu/` — the ubuntu tool chain, one page per layer
- `docs/source/51-macos-legacy/` — the macports tool chain, one page per layer
- `src/macos-legacy/` — the setup scripts the macos pages include with `{literalinclude}`;
  edit scripts here, never inside the markdown
- `docs/source/conf.py` — sphinx configuration, edit inside the `## change required` blocks
- `bin/` — build, live-reload and packaging helpers inherited from the template
- `.github/workflows/build.yml` — builds and publishes to github pages on push to `main`

## build locally

```bash
python3 -m venv ~/.venv --system-site-packages   # once
source ~/.venv/bin/activate
pip install -r docs/requirements.txt             # once
make -C docs html                                # output in docs/build/html
```

or with live reload:

```bash
bin/live-docs.sh
```

## adding a platform section

```bash
bin/new-section.sh 01-gentoo
```

then wire `01-gentoo/index` into the `toctree` in `docs/source/index.md`. An unwired page is
reported as orphaned at build time.

## credits

built from [furo-embeded](https://github.com/brucekomike/furo-embeded), a sphinx template with
the furo theme and a github pages workflow.
