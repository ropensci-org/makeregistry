#!/bin/bash

error_exit()
{
    echo "$1" 1>&2
    exit 1
}

get_repos()
{
    for x in 1 2 3
    do
      echo "working on $x loop"
      url=$(printf 'https://api.github.com/orgs/ropenscilabs/repos?per_page=100&page=%s' $x)
      curl -s -H "Authorization: token <replace me: GITHUB_PAT_SCOTT>" $url | ruby -e 'ex=File.read("/home/ubuntu/exclude_list.txt").split; require "json"; JSON.load(STDIN.read).each { |repo| puts repo["name"]; %x[git clone --depth 1 #{repo["html_url"]}] unless File.directory?(repo["name"]) || repo["archived"] || ex.include?(repo["name"]) }'
    done
}


if rm -rf */; then
    if get_repos; then
        echo "yay!"
    else
        error_exit "for loop didn't work"
    fi
else
    error_exit "Cannot delete folders! Aborting."
fi
