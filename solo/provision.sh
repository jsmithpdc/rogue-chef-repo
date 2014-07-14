#!/bin/bash
# exit if anything returns failure
set -e

cd /opt/rogue-chef-repo

# activate the correct rvm environment
source /usr/local/rvm/scripts/rvm

type rvm | head -1
git pull
berks update
rm -rf /opt/chef-run/cookbooks
berks vendor /opt/chef-run/cookbooks
rvmsudo chef-solo -c /opt/chef-run/solo.rb -j /opt/chef-run/dna.json
