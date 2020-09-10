#!/bin/sh

ruby git_urls.rb

# if make registry did not fail, proceed
if [ $? -eq 0 ]; then
  echo "pushing up packages.json"
  # go into roregistry dir, pull any changes
  echo "pulling any changes in roregistry"
  git clone https://github.com/ropensci/roregistry.git
  cd roregistry
  git fetch origin
  git reset --hard origin/gh-pages

  # copy files into roregistry directory
  echo "copy packages.json into roregistry"
  cp ../packages.json .

  # upload new registry files to github
  echo "pushing changes to github"
  git commit -am 'packages.json updated'
  git push

  # cd back to home dir
  cd ..
fi
