#!/bin/bash

if test ! $(which atuin)
then
  echo "› Configuring atuin"
  echo 'eval "$(atuin init zsh)"' >> ~/.zshrc
else
  echo "Atuin already installed"
fi
