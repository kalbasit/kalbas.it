#!/usr/bin/env bash
set -ex

mkdir -p "${GOPATH}/src/github.com/spf13"
git clone --branch=$HUGO_VERSION https://github.com/spf13/hugo.git "${GOPATH}/src/github.com/spf13/hugo"
cd "${GOPATH}/src/github.com/spf13/hugo"
go get github.com/kardianos/govendor
govendor sync github.com/spf13/hugo
make install
pip install -r requirements.txt
