#!/bin/bash

error_exit()
{
    echo "$1" 1>&2
    exit 1
}

check_exclude_list()
{
    ruby -e 'ff = File.read("../../inst/automation/exclude_list.txt"); !ff.match?("ropensci_citations") ? raise("exclude_list.txt read failure") : nil'
}

get_repos()
{
    for x in 1 2
    do
      echo "working on $x loop"
      url=$(printf 'https://api.github.com/orgs/ropenscilabs/repos?per_page=100&page=%s' $x)
      curl -s $url | ruby -e 'ex=File.read("../../inst/automation/exclude_list.txt").split; require "json"; JSON.load(STDIN.read).each { |repo| puts repo["name"]; %x[git clone --depth 1 #{repo["html_url"]}] unless File.directory?(repo["name"]) || repo["archived"] || ex.include?(repo["name"]) }'
    done
}

if rm -rf */; then
    if check_exclude_list; then
      if get_repos; then
          echo "yay!"
      else
          error_exit "for loop didn't work"
      fi
    else
      error_exit "exclude_list file is bad"
    fi
else
    error_exit "Cannot delete folders! Aborting."
fi
