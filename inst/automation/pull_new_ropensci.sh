#!/bin/bash
for x in 1 2 3 4
do
  echo "working on $x loop"
  url=$(printf 'https://api.github.com/orgs/ropensci/repos?per_page=100&page=%s' $x)
  curl -s $url | ruby -e 'ex=File.read("/home/ubuntu/exclude_list.txt").split; require "json"; JSON.load(STDIN.read).each { |repo| puts repo["name"]; %x[git clone #{repo["html_url"]}] unless File.directory?(repo["name"]) || repo["archived"] || ex.include?(repo["name"]) }'
done
