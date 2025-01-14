#!/usr/bin/env sh

# abort on errors
set -e

# build
npm run build

# navigate into the build output directory
cd dist

# create a temporary directory and copy the dist contents
mkdir -p /tmp/gh-pages
cp -r . /tmp/gh-pages/

# go back to the root of the project
cd ..
cd ..

# checkout gh-pages branch
git checkout gh-pages

# remove existing contents
rm -rf assets index.html .nojekyll

# copy new contents
cp -r /tmp/gh-pages/* .

# cleanup
rm -rf /tmp/gh-pages

# add and commit changes
git add -A
git commit -m 'deploy: update demo site'

# push to gh-pages branch
git push -f origin gh-pages

# go back to previous branch
git checkout -
