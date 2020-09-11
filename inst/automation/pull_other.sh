#!/bin/bash

rm -rf */

cp ../../inst/automation/not_transferred.txt .
mapfile -t arr < not_transferred.txt

for x in "${arr[@]}"
do
  git clone --depth 1 $x
done
# should take about 20 sec.

rm not_transferred.txt
