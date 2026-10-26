#!/bin/sh
# Copy only the public app files into dist/ (nothing else from the repo is published)
set -e
rm -rf dist && mkdir -p dist
cp index.html staff.html privacy.html delete-account.html _headers sw.js icon-192.png icon-512.png icon-maskable.png badge-96.png manifest.webmanifest dist/
cp -r lib dist/
cp -r icons3d dist/
# Style 4 இயல்பு படங்கள் (WebP)
cp -r img dist/
# Android app (Trusted Web Activity) needs /.well-known/assetlinks.json to hide the address bar
cp -r .well-known dist/
