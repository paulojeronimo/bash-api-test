#!/usr/bin/env bash

cd

yes | pkg install tmux vim git python nodejs jq yq

pip install --upgrade pip
pip install httpie

npm install npm@latest -g
npm install -g json-server

repo=https://github.com/paulojeronimo/bash-api-test
repo_dir=$(basename $repo)
if ! [ -d $repo_dir ]
then
  git clone $repo
else
  echo Directory \"$PWD/$repo_dir\" already exists!
  echo Skipped \"git clone $repo\" ...
fi

cd $repo_dir
