#!/bin/bash
set -e

# download go
GO_VERSION="1.24.2"
wget https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz

# install go
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf go${GO_VERSION}.linux-amd64.tar.gz

# add to ~/.bashrc
echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
echo 'export PATH=$PATH:$HOME/go/bin' >> ~/.bashrc

# verify go
source ~/.bashrc
go version

# install hugo
go install github.com/gohugoio/hugo@latest
