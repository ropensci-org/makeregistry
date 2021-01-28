#!/bin/sh

# make registry in R
echo "making new registry"
Rscript make_registry.R

# if make registry did not fail, proceed
if [ $? -eq 0 ]; then
  # go into roregistry dir, pull any changes
  echo "pulling any changes in roregistry"
  git clone https://REPO_PAT:$REPO_PAT@github.com/ropensci/roregistry.git
  cd roregistry
  git remote add origin https://REPO_PAT:$REPO_PAT@github.com/ropensci/roregistry.git
  git fetch origin
  git reset --hard origin/gh-pages

  # copy files into roregistry directory
  echo "copying registry files into roregistry"
  cp ../registry.json .
  cp ../raw_cm.json .

  pkgslength=$(jq .packages ../registry.json | jq length)
  if [  $pkgslength -gt 250 ]; then
    # upload new registry files to github
    echo "pushing changes to github"
    git commit -am 'registry.json and raw_cm.json updated'
    git push
  else
    echo "Only $pkglength package(s), this is not good. :-("
    exit 1
  fi

  # cd back to home dir
  cd ..
fi
