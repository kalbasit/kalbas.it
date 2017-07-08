#!/usr/bin/env bash
set -ex

mkdir -p "${GOPATH}/src/github.com/gohugoio"
git clone --branch="${HUGO_VERSION}" https://github.com/gohugoio/hugo.git "${GOPATH}/src/github.com/gohugoio/hugo"
cd "${GOPATH}/src/github.com/gohugoio/hugo"
make vendor install
pip install -r requirements.txt
