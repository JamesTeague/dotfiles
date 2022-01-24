#!/bin/bash

echo git username:
read git_username;

echo git email:
read git_email;

echo Brewfile repo:
read brewfile_repo;

if [[ "$OSTYPE" == "linux-gnu"* ]]; then
  sudo apt-get install zsh;
  chsh -s /bin/zsh;
fi

echo Checking for brew...
if ! command -v brew &> /dev/null
then
  echo Installing brew...
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)";
  if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> ~/.zprofile; 
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)";
  fi
fi

echo Installing brew packages from Brewfile...
brew file set_repo -r $brewfile_repo;
brew file install;

echo Configuring git...
git config --global core.editor nvim;
git config --global push.default simple;
git config --global core.autocrlf input;
git config --global user.name $git_username;
git config --global user.email $git_email;

echo Downloading cht.sh with completions...
sudo curl https://cht.sh/:cht.sh > /usr/local/bin
sudo chmod +x /usr/local/bin/cht.sh
curl https://cheat.sh/:zsh > ~/.zsh/_cht;

echo Configuring oh-my-zsh...
sudo sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"

echo Moving .zshrc to .zsrhc.pre_bootstrap...
mv ~/.zshrc ~/.zshrc.pre_bootstrap;
echo Linking .zshrc...
ln .zshrc ~/.zshrc;

echo Moving .p10k.zsh to .p10k_zsh.pre_bootstrap...
mv ~/.p10k.zsh ~/.p10k_zsh.pre_bootstrap;
echo Linking .p10k.zsh...
ln .p10k.zsh ~/.p10k.zsh

echo Done. Run "source ~/.zshrc" or open a new terminal.
