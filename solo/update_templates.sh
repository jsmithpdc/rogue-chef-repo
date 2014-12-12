#!/bin/bash
# exit if anything returns failure
set -e

# Uses chef-solo to execute the `update_templates` recipe.

# The `update_templates` recipe updates application configuration
# files with the current IP of the machine, without making any
# requests to the internet.

rvmsudo chef-solo -c /opt/chef-run/solo.rb -j /opt/chef-run/dna.json -o "recipe[rogue::update_templates]"

service tomcat7 restart
supervisorctl restart rogue

/var/lib/geonode/bin/python /var/lib/geonode/rogue_geonode/manage.py update-layer-ips
