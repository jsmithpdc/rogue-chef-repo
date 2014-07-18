#!/bin/bash
# exit if anything returns failure
set -e

# store current directory
pushd .

cd /opt/rogue-chef-repo
git pull
berks update
rm -rf /opt/chef-run/cookbooks
berks vendor /opt/chef-run/cookbooks

# Note: cannot be in the /opt/rogue-chef-repo when running this command.
#       ruby shadow install failes because chef failes to find some 
#       packages such as pg and shadow
cd /opt/chef-run
chef-solo -c /opt/chef-run/solo.rb -j /opt/chef-run/dna.json

# restore stored directory
popd
