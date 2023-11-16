#!/bin/bash

if [ ! -d $ZSH ]; then
  echo Configuring oh-my-zsh
  sudo sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
fi
