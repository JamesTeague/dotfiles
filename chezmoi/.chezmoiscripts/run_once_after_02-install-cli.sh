#!/bin/bash

if [ ! -d $ZSH ]; then
  echo "› Configuring oh-my-zsh"
  sudo sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
else
  echo "Oh-my-zsh already installed"
fi

if test ! $(which rustup)
then
  echo "› Installing rustup"
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
else
  echo "Rustup already installed"
fi

tmuxHome=$(echo $HOME)/.tmux/plugins/tpm
if [ ! -d $tmuxHome ]; then
  echo "› Installing tmux plugin manager"
  git clone https://github.com/tmux-plugins/tpm $tmuxHome
else
  echo "Tmux plugin manager already installed"
fi
