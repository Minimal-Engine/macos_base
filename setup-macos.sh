#!/bin/bash

# system-settings

## deactivate SIRI
defaults write com.apple.assistant.support "Assistant Enabled" -bool false

## deavtivate STAGE-MANAGER
defaults write com.apple.WindowManager GloballyEnabled -bool false

## disable all hot-corners
defaults write com.apple.dock wvous-tl-corner -int 0
defaults write com.apple.dock wvous-tr-corner -int 0
defaults write com.apple.dock wvous-bl-corner -int 0
defaults write com.apple.dock wvous-br-corner -int 0

## autohide the dock, remove recent apps
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock show-recents -bool NO
killall Dock

## always hide menu bar
defaults write NSGlobalDomain _HIHideMenuBar -bool true


# install brew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# pull my dotfiles
