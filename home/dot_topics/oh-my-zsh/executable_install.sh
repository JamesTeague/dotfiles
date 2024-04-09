#!/bin/bash

if [ -z $ZSH ] || [ ! -d $ZSH ]; then
  echo "› Configuring oh-my-zsh"
  sudo sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"

  if [ -f ~/.zshrc.pre-oh-my-zsh ]; then
    mv -f .zshrc.pre-oh-my-zsh .zshrc
  fi
else
  echo "Oh-my-zsh already installed"
fi
