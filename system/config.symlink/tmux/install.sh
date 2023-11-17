#!/bin/bash

# echo Linking .tmux.conf...
# mkdir -p $(echo $HOME)/.config/tmux
# ln -sf $(pwd)/tmux.conf $(echo $HOME)/.config/tmux/tmux.conf

tmuxHome=$(echo $HOME)/.tmux/plugins/tpm
if [ ! -d $tmuxHome ]; then
  echo installing tmux plugin manager
  git clone https://github.com/tmux-plugins/tpm $tmuxHome
else
  echo tmux plugin manager already installed
fi
