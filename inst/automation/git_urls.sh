#!/bin/sh

ruby git_urls.rb

echo "pushing up registry_urls.json"
# if make registry did not fail, proceed
if [ $? -eq 0 ]; then
  # go into roregistry dir, pull any changes
  echo "pulling any changes in roregistry"
  cd roregistry
  git fetch origin
  git reset --hard origin/gh-pages

  # copy files into roregistry directory
  echo "copy registry_urls.json into roregistry"
  cp ../registry_urls.json .

  # upload new registry files to github
  echo "pushing changes to github"
  git commit -am 'registry_urls.json updated'
  git push

  # cd back to home dir
  cd ..
fi
