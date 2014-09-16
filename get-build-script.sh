#! /bin/bash -ex

git remote set-url origin https://github.com/gaborcsardi/r-builder
git fetch origin master
git show origin/master:r-build.sh > r-build.sh
chmod +x r-build.sh
