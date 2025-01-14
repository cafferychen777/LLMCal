#!/usr/bin/env sh

# abort on errors
set -e

# build
npm run build

# create a temporary directory and copy the dist contents
mkdir -p /tmp/gh-pages
cp -r dist/* /tmp/gh-pages/

# checkout gh-pages branch
git checkout gh-pages

# remove existing contents except .git
find . -maxdepth 1 ! -name '.git' ! -name '.' ! -name '..' -exec rm -rf {} +

# copy new contents
cp -r /tmp/gh-pages/* .

# ensure .nojekyll exists
touch .nojekyll

# cleanup
rm -rf /tmp/gh-pages

# add and commit changes
git add -A
git commit -m 'deploy: update demo site'

# push to gh-pages branch
git push origin gh-pages

# go back to previous branch
git checkout -
