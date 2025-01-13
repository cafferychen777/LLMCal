#!/usr/bin/env sh

# abort on errors
set -e

# build
npm run build

# navigate into the build output directory
cd dist

# place .nojekyll to bypass Jekyll processing
touch .nojekyll

git init
git checkout -B main
git add -A
git commit -m 'deploy'

# push to gh-pages branch using GITHUB_TOKEN environment variable
git push -f https://${GITHUB_TOKEN}@github.com/cafferychen777/LLMCal.git main:gh-pages

cd -
