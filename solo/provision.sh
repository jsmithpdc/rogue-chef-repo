#!/usr/bin/env bash

cd /opt/rogue-chef-repo
source /home/rogue/.rvm/scripts/rvm
type rvm | head -1
git pull
berks update
berks vendor /opt/chef-run/cookbooks
rvmsudo chef-solo -c /opt/chef-run/solo.rb -j /opt/chef-run/dna.json
