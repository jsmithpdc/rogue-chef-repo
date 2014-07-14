#!/bin/bash
# exit if anything returns failure
set -e

sudo apt-get install -y curl

curl -L https://get.rvm.io | bash -s $1
