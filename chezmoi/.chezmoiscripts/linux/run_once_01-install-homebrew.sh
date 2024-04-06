#!/bin/sh

# exist checks if a command exist in shell
exist() {
  command -v "$1" >/dev/null 2>&1
}

info () {
  printf "\r  [ \033[00;34m..\033[0m ] $1\n"
}

user () {
  printf "\r  [ \033[0;33m??\033[0m ] $1\n"
}

success () {
  printf "\r\033[2K  [ \033[00;32mOK\033[0m ] $1\n"
}

fail () {
  printf "\r\033[2K  [\033[0;31mFAIL\033[0m] $1\n"
  echo ''
  exit
}

info "Installing Linux Tooling..."

if exists brew
then
  info "Updating Homebrew..."
  brew update
else
  info "Installing Homebrew for you."

  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> $(echo $HOME)/.zprofile 
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

