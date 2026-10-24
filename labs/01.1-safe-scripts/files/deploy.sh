#!/bin/bash
# Copy a release into site/current. Usage: ./deploy.sh RELEASE
release=$1
cd site
rm -rf current/*
cp -r ../releases/$release/* current/
echo "deployed $release"
