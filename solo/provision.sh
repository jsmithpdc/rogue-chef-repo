#!/usr/bin/env bash
# store current directory
pushd .

cd /opt/rogue-chef-repo
git pull
berks update
rm -rf /opt/chef-run/cookbooks
berks vendor /opt/chef-run/cookbooks

# Note: cannot be in the /opt/rogue-chef-repo when running this command.
#       ruby shadow install failes!
cd /opt/chef-run
rvmsudo chef-solo -c /opt/chef-run/solo.rb -j /opt/chef-run/dna.json
# restore stored directory
popd
