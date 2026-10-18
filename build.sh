#!/bin/sh
# Copy only the public app files into dist/ (nothing else from the repo is published)
set -e
rm -rf dist && mkdir -p dist
cp index.html staff.html _headers sw.js icon-192.png dist/
cp -r lib dist/
