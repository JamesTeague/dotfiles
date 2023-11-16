#!/bin/bash

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
  mkdir -p ~/Screenshots
  defaults write com.apple.screencapture "location" -string "~/Screenshots"
  killall SystemUIServer

  echo Configuring Desktop Services.
  defaults write com.apple.desktopservices DSDontWriteNetworkStores true
fi

