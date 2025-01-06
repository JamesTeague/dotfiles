#!/bin/bash

if test ! $(which posting)
then
  echo "› Installing posting"
  uv tool install --python 3.12 posting
else
  echo "Posting already installed"
fi
