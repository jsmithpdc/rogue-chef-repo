#!/bin/bash
# exit if anything returns failure
set -e

# Uses chef-solo to execute the `update_templates` recipe.

# The `update_templates` recipe updates application configuration
# files with the current IP of the machine, without making any
# requests to the internet.

rvmsudo chef-solo -c /opt/chef-run/solo.rb -j /opt/chef-run/update_templates.json
service tomcat7 restart
supervisorctl restart rogue
