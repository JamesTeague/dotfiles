#!/bin/bash

if test ! $(which posting)
then
  echo "› Installing posting"
  brew install uv
  if uv tool install --python 3.12 posting; then
    brew uninstall uv
    echo "› Installed Posting"
  else
    echo "› Falling back to pipx"
    brew uninstall uv
    brew install pipx
    export PIPX_DEFAULT_PYTHON="$(which python3)"
    pipx install --python 3.12 --fetch-missing-python posting
    brew uninstall pipx
    echo "› Installed Posting"
  fi
else
  echo "Posting already installed"
fi
