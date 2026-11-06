#!/usr/bin/env bash

if (! command -v sphinx-autobuild ) ; then
  pip install -r ./docs/requirements.txt
fi

if [[ -f ./docs/build/html/index.html ]]; then
  if [[ -t 0 ]]; then
    read -r -p "Previous build found in docs/build — purge and do a full rebuild? [y/N] " ans
    if [[ "$ans" =~ ^[Yy] ]]; then
      # -E: ignore cached environment, -a: rewrite every page
      make -C docs html SPHINXOPTS="-aE"
      echo "full rebuild done, starting live server"
    else
      echo "keeping existing build, starting incremental"
    fi
  else
    echo "note: docs/build exists but stdin is not a terminal — skipping purge"
  fi
fi

sphinx-autobuild ./docs/source ./docs/build/html