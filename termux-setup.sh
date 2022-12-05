#!/usr/bin/env bash

repo_service=${repo_service:-https://github.com}
repo=${repo:-paulojeronimo/bash-api-test}
dotdir=.${repo#*/}
repo_tag=${1:-main}
LOG_LINK=termux-install.log

is-installed() {
  command -v $1 > /dev/null || return $?
  echo $1 is already installed!
}

log() {
  local log_file=~/$dotdir/$LOG_LINK
  local cmd="$@"
  echo "$cmd"
  echo -e "[$(date +%X) BEGIN]: $cmd\n----" &>> $log_file
  if ! $cmd &>> $log_file
  then
    echo -e "\tSome error occurred!"
    echo -e "\tPlease, see the details in" \~/$dotdir/$LOG_LINK
  else
    echo -e "----\n[$(date +%X) END]: $cmd" &>> $log_file
    echo &>> $log_file
  fi
}

pkg-install() {
  local installed_pkgs=$(
    pkg list-installed 2>/dev/null | \
    tail -n +2 | cut -d'/' -f1)
  for pkg in "$@"
  do
    if grep -q -w $pkg <<< "$installed_pkgs"
    then
      echo $pkg is already installed!
      continue
    fi
    yes | log pkg install $pkg
    case $pkg in
      python) log pip install --upgrade pip;;
      nodejs) : 
        # There is a bug when updating to latest npm: https://github.com/termux/termux-packages/issues/13293
        #   Related to https://github.com/npm/cli/issues/5114
        #log npm install npm@latest -g
        ;;
    esac
  done
}

cd
mkdir -p ~/$dotdir
ln -sf $(mktemp) ~/$dotdir/$LOG_LINK
echo Configuring your Termux. Please, be patient!
upgraded=~/$dotdir/pkg-upgrade
if ! [ -f $upgraded ]
then
  echo Upgrading packages ...
  yes | log pkg upgrade
  log pkg update
  touch $upgraded
fi
pkg-install tmux vim git python nodejs jq yq
is-installed httpie || log pip install httpie
is-installed json-server || log npm install -g json-server

repo_dir=$(basename $repo)
if ! [ -d $repo_dir ]
then
  log git clone $repo_service/$repo
  echo Changing the current directory to \~/$repo_dir \(branch $repo_tag\)
  cd $repo_dir
  log git checkout $repo_tag
else
  echo Changing the current directory to \~/$repo_dir
  cd $repo_dir
fi

echo Your Termux was successfully configured! \\0/
