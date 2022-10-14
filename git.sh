#!/bin/bash
 
# The MIT License (MIT)
# Copyright (c) 2013 Alvin Abad
 
if [ $# -eq 0 ]; then
    echo "Git wrapper script that can specify an ssh-key file
Usage:
    git.sh -i ssh-key-file git-command
    "
    exit 1
fi
 
# remove temporary file on exit
trap 'rm -f /tmp/.git_ssh.$$' 0
 
if [ "$1" = "-i" ]; then
    SSH_KEY=$2; shift; shift
    echo "ssh -i $SSH_KEY \$@" > /tmp/.git_ssh.$$
    chmod +x /tmp/.git_ssh.$$
    export GIT_SSH=/tmp/.git_ssh.$$
fi
 
# in case the git command is repeated
[ "$1" = "git" ] && shift
 
# Run the git command
#git "$@"

## modify by lonelyer@20210204
## 修改git外部执行进程为 /v/bin/git2,取代默认/usr/bin/git，以便于自动使用代理
/v/bin/git2 "$@"
#bash -x /v/bin/git2 "$@" # for debug git2