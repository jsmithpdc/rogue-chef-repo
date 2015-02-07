#!/bin/bash
# exit if anything returns failure
set -e

if [ "$1" = "silent" ];
then
  GEOSHAPE_SILENT=true
  GEOSHAPE_VERSION="$2"
elif [ "$2" = "silent" ];
then
  GEOSHAPE_SILENT=true
  GEOSHAPE_VERSION="$1"
else
  GEOSHAPE_VERSION="$1"
fi

if [ "$GEOSHAPE_SILENT" != true ]; then
    echo "====[ WARNING:
      You are attempting to upgrade the installation of geoshape. Before proceeding, you should backup
      this machine. If it is a virtual machine, you should create a snapshot so that you can undo the changes
      if there are any incompatibilities. In some cases, the database may no longer operate as expented resulting
      in potential loss of data. Note that only some upgrades can complete successfully! Before continuing
      you should review changes introduced between the geoshape version you are currently on and the version
      you are attempting to upgrade to. There could be many backwards incompatible changes introduced at
      any of the geoshape dependencies. In some cases, a clean installation of geoshape might be necessary
      to get the latest functionality successfully. For example, the geoserver_data directory required by
      the latest version of geoshape, may contain some configuration or scripts that doesn't make it
      possible to simply keep your current /var/lib/geoserver_data directory. Similar issues could arise for
      many other dependencies of geoshape. This script is only intended for advanced users! The safest way
      the to upgrade geoshape is to create a new instance and migrate your data."

    while true; do
        read -p "=> Are you sure you want to continue? " yn
        case $yn in
            [Yy]* ) break;;
            [Nn]* ) echo "    geoshape upgrade exited. ";exit;;
            * ) echo "    Please answer yes or no.";;
        esac
    done
fi

# store current directory
pushd .

cd /opt/rogue-chef-repo

# get latest tags/branchs
git fetch

if [ -z "$GEOSHAPE_VERSION" ];
then
  # discover the latest release tag
  RELEASE_TAGS=(`git tag`)
  echo 'release tags: '
  echo "${RELEASE_TAGS[@]}"
  # sort the list of branches that had '.' in them such that index 0 is the largest one
  RELEASE_TAGS_SORTED=($(printf '%s\n' "${RELEASE_TAGS[@]}"|sort -r))
  UPGRADE_TO_GEOSHAPE_VERSION=${RELEASE_TAGS_SORTED[0]}
fi

if [ -z "$GEOSHAPE_VERSION" ];
then
    echo 'Note: geoshape version was not specified, did you intend to upgrade to release: '${UPGRADE_TO_GEOSHAPE_VERSION}
    while true; do
        read -p "=> Are you sure you want to continue? " yn
        case $yn in
            [Yy]* ) break;;
            [Nn]* ) echo "    geoshape upgrade exited. ";exit;;
            * ) echo "    Please answer yes or no.";;
        esac
    done
fi

GEOSHAPE_VERSION=$UPGRADE_TO_GEOSHAPE_VERSION

# checkout the requests 'version' (tag, branch, commit)
git checkout ${GEOSHAPE_VERSION}

# if on a branch, do a pull to get latest on local branch. When a branch is used, user essentially wants the latets
# 'snapshot' from the specified branch (version)
CURRENT_BRANCH=`git branch | sed -n '/\* /s///p'`
if ["$CURRENT_BRANCH" != "(no branch)"]
then
  git pull
fi

bundle update
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
