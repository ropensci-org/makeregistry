#!/bin/bash

rm -rf */

curl https://raw.githubusercontent.com/ropenscilabs/makeregistry/master/inst/automation/not_transferred.txt > not_transferred.txt
mapfile -t arr < not_transferred.txt

for x in "${arr[@]}"
do
  git clone --depth 1 $x
done
# should take about 20 sec.

rm not_transferred.txt
