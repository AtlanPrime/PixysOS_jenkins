#!/usr/bin/env bash
#
# Copyright (C) 2019 PixysOS project.
#
# Licensed under the General Public License.
# This program is free software; you can redistribute it and/or modify
# in the hope that it will be useful, but WITHOUT ANY WARRANTY;
#
#
# PixysOS Github Push script.

[[ -z "${GITHUB_USERNAME}" || -z "${GITHUB_PASSWORD}" ]] && echo "Variable GITHUB_USERNAME and GITHUB_PASSWORD is not defined!" && post_auth_error || push

function post_auth_error() {
    echo "Do you have a GitHub API key with push access defined under variable GITHUB_API_KEY? Reply with \"yes\" or \"no\""
    read -r new_auth
    if [ -z "${GITHUB_API_KEY}" ] && [ "$new_auth" = "yes" ] ;
    then
        export USE_API_KEY="true"
        echo "API_KEY detected. Proceeding next step..."
        push
    fi
    echo "Seems like your authentication method is relying on SSH. Do you want to proceed that way? Reply with \"no\" if you want to exit or press any button to proceed to push"
    read -r ssh_auth
    if [ "$ssh_auth" == "no" ];
    then
        echo "Aborting push...With exit code 1"
        exit 1
    fi
    export USE_SSH_KEY="true"
    push
}

function push() {
cwd=$PWD
branch="ten"
org="PixysOS"
cd ~/pixys || exit
if [ ! -f ".repo/manifests/snippets/pixys.xml" ];
then
    echo "Manifest file not found exiting....."
    echo "Be sure to keeep the script inside Android Builds Top dir"
    exit 1
fi
echo "Do you want to force push? Reply with \"yes\" or \"no\""
read -r force_push
if [ "$force_push" = "yes" ];
then
    FORCE_PUSH="-f"
fi

PROJECTS="$(grep 'pixys' .repo/manifests/snippets/pixys.xml  | awk '{print $2}' | awk -F'"' '{print $2}' | uniq | grep -v caf)"
for project in ${PROJECTS}
do
    cd "$project" || exit
    echo "$project"
    repo_name=$(git remote -v | head -1 | awk '{print $2}' | sed -e 's/https:\/\/github.com\/PixysOS\///')
    if [ "$USE_API_KEY" = "true" ];
    then
        git push "${FORCE_PUSH}" https://"${GITHUB_API_KEY}"@github.com/${org}/"${repo_name}" HEAD:${branch}
    elif [ "$USE_SSH_KEY" = "true" ];
    then
        git push "${FORCE_PUSH}" ssh://git@github.com/${org}/"${repo_name}" HEAD:${branch}
    else
        git push  "${FORCE_PUSH}" https://"${GITHUB_USERNAME}:${GITHUB_PASSWORD}":@github.com/${org}/"${repo_name}" HEAD:${branch}
    fi
    cd - || exit
done
cd "$cwd" || exit
exit
}