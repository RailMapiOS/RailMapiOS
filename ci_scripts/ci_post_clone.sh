#!/bin/zsh
cd ..
curl -Ls https://install.tuist.io | bash

export HOMEBREW_CASK_OPTS="--appdir=$HOME/Applications"
brew install --cask tuist

mkdir -p ~/.tuist
curl -Ls https://github.com/tuist/tuist/releases/latest/download/tuist.zip -o ~/.tuist/tuist.zip
unzip ~/.tuist/tuist.zip -d ~/.tuist
chmod +x ~/.tuist/tuist
export PATH="$HOME/.tuist:$PATH"

tuist generate
