#!/bin/bash

if test ! $(which harlequin)
then
  echo "› Installing harlequin"
  python3 -m pip install harlequin-postgres
  python3 -m pip install harlequin-mysql
else
  echo "harlequin already installed"
fi
