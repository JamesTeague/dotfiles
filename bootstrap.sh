#!/bin/bash

echo git username:
read git_username;

echo git email:
read git_email

echo Personal Setup? [y/n]
read personal_setup

if [[ "$OSTYPE" == "linux-gnu"* ]]; then
  sudo apt-get update
  sudo apt-get install zsh
  chsh -s /bin/zsh
fi

echo Checking for brew...
which -s brew
if [[ $(command -v brew) == "" ]]; then
  echo Installing brew...
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> $(echo $HOME)/.zprofile 
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
  elif [[ "$OSTYPE" == "darwin"* ]]; then
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> $(echo $HOME)/.zprofile
    eval "$(/opt/homebrew/bin/brew shellenv)"
  fi
fi

echo Installing brew packages from Brewfile...
brew bundle;

if [[ "$OSTYPE" == "darwin"* ]]; then
  echo Changing macOS defaults...

  # defaults write com.apple.Accessibility ReduceMotionEnabled -bool true

  echo Configuring finder and hiding unwanted desktop items.
  defaults write com.apple.finder ShowExternalHardDrivesOnDesktop -bool false
  defaults write com.apple.finder ShowHardDrivesOnDesktop -bool false
  defaults write com.apple.finder ShowRemovableMediaOnDesktop -bool false
  defaults write com.apple.finder ShowMountedServersOnDesktop -bool false
  defaults write com.apple.Finder AppleShowAllFiles true
  killall Finder

  echo Configuring Dock and Mission Control.
  defaults write com.apple.dock no-bouncing -bool true
  defaults write com.apple.dock orientation right 
  defaults write com.apple.dock autohide -bool true
  defaults write com.apple.dock show-recents -bool false
  # Turns off misson control rearrange spaces
  defaults write com.apple.dock mru-spaces -bool false
  # disable hot corners
  defaults write com.apple.dock wvous-tl-corner -int 0
  defaults write com.apple.dock wvous-tr-corner -int 0
  defaults write com.apple.dock wvous-bl-corner -int 0
  defaults write com.apple.dock wvous-br-corner -int 0
  killall Dock

  echo Fixing mouse scroll direction.
  defaults write -g com.apple.swipescrolldirection -bool false

  echo Setting screenshots to jpg and disabling shadows.
  defaults write com.apple.screencapture disable-shadow -bool true
  defaults write com.apple.screencapture type jpg
  mkdir ~/Screenshots
  defaults write com.apple.screencapture "location" -string "~/Screenshots"
  killall SystemUIServer

  echo Configuring Desktop Services.
  defaults write com.apple.desktopservices DSDontWriteNetworkStores true

  # echo Copying Karabiner configuration...
  # cp -r ./karabiner ~/.config
fi

echo Moving .gitignore to .gitignore.pre_bootstrap...
mv $(echo $HOME)/.gitignore $(echo $HOME)/.gitignore.pre_bootstrap
echo Linking .gitignore...
ln -sf $(pwd)gitignore $(echo $HOME)/.gitignore

echo Configuring git...
git config --global core.editor nvim
git config --global push.default simple
git config --global core.autocrlf input
git config --global pull.rebase false
git config --global user.name $git_username
git config --global user.email $git_email
git config --global core.excludesfile ~/.gitignore

echo Downloading cht.sh with completions...
sudo touch /usr/local/bin/cht.sh
sudo curl -s https://cht.sh/:cht.sh | sudo tee /usr/local/bin/cht.sh
sudo chmod +x /usr/local/bin/cht.sh
curl https://cheat.sh/:zsh > $(echo $HOME)/.zsh/_cht --create-dirs

echo Configuring oh-my-zsh...
sudo sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"

echo Moving .zshrc to .zsrhc.pre_bootstrap...
mv $(echo $HOME)/.zshrc $(echo $HOME)/.zshrc.pre_bootstrap
echo Linking .zshrc...
ln -sf $(pwd)/zshrc $(echo $HOME)/.zshrc

if [[ $personal_setup = "n" ]] 
then
  echo Tailoring the work experience...

  echo 'export GOPRIVATE="scm.bluebeam.com/nw/proto"' >> $(echo $HOME)/.zshrc
  brew bundle --file=$(pwd)/Brewfile.Work
else
  echo Adding personal touches...

  brew bundle --file=$(pwd)/Brewfile.Personal
fi

echo Moving .p10k.zsh to .p10k_zsh.pre_bootstrap...
mv $(echo $HOME)/.p10k.zsh $(echo $HOME)/.p10k_zsh.pre_bootstrap;
echo Linking .p10k.zsh...
ln -sf $(pwd)/p10k.zsh $(echo $HOME)/.p10k.zsh

echo Moving .config/nvim to .config/nvim.pre_boostrap...
mv $(echo $HOME)/.config/nvim $(echo $HOME)/.config/nvim.pre_boostrap
mkdir -p $(echo $HOME)/.config/nvim
echo Linking .config/nvim directory to nvim
ln -sf $(pwd)/nvim $(echo $HOME)/.config/nvim 

echo Moving .ideavimrc to .ideavimrc.pre_boostrap...
mv $(echo $HOME)/.ideavimrc $(echo $HOME)/.ideavimrc.pre_bootstrap
echo Linking .ideavimrc for IntelliJ...
ln -sf $(pwd)/ideavimrc $(echo $HOME)/.ideavimrc

echo Installing packer for neovim...
git clone --depth 1 https://github.com/wbthomason/packer.nvim\
 $(echo $HOME)/.local/share/nvim/site/pack/packer/start/packer.nvim

echo Done. Run "source ~/.zshrc" or open a new terminal.
