#!/bin/bash

if test ! $(which rustup)
then
  echo "› Installing rustup"
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
else
  echo "Rustup already installed"
fi
