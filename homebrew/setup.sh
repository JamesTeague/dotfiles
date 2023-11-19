#!/bin/bash
#
# Homebrew
#
# This installs some of the common dependencies needed (or at least desired)
# using Homebrew.

personal=

while getopts 'pw' flag; do
  case "${flag}" in
    p) personal=true ;;
    w) personal=false ;;
    *) exit 1 ;;
  esac
done

# Check for Homebrew
if test ! $(which brew)
then
  echo "  Installing Homebrew for you."

  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  # Install the correct homebrew for each OS type
  if test "$(uname)" = "Darwin"
  then
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> $(echo $HOME)/.zprofile
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif test "$(expr substr $(uname -s) 1 5)" = "Linux"
  then
    echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> $(echo $HOME)/.zprofile 
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
  fi
fi

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "   Installing brew packages from Brewfile."
brew bundle --file=${script_dir}/Brewfile;

if ! $personal 
then
  echo Tailoring the work experience...

  brew bundle --file=${script_dir}/Brewfile.Work
else
  echo Adding personal touches...

  brew bundle --file=${script_dir}/Brewfile.Personal
fi

exit 0
