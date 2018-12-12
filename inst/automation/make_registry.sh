#!/bin/sh

# make registry in R
echo "making new registry"
Rscript make_registry.R

# if make registry did not fail, proceed
if [ $? -eq 0 ]; then
  # go into roregistry dir, pull any changes
  echo "pulling any changes in roregistry"
  cd roregistry
  git pull

  # copy files into roregistry directory
  echo "copying registry files into roregistry"
  cp ../registry.json .
  cp ../raw_cm.json .

  # upload new registry files to github
  echo "pushing changes to github"
  git commit -am 'registry.json and raw_cm.json updated'
  git push

  # cd back to home dir
  cd ..
fi

# clean tar files
echo "\n\n\n"
echo "cleaning out .tar.gz files"
for d in repos/* ; do
  echo "$d"
  cd $d
  rm *.tar.gz
  cd ../../
done
