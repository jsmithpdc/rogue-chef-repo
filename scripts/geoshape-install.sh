#!/bin/bash
# exit if anything returns failure
set -e

#-- parse parameters to see if a geoshape version and/or the parameter 'vagrant' have been passed in.
#   if vagrant is passed in, any other parameter will be used as geoshape version. if only one
#   param is passed in and it is not 'vagrant', it will be used as the GEOSHAPE varions.
#   valid usage examples:
#   geoshape-install.sh release-1.2
#   geoshape-install.sh release-1.1 vagrant
#   geoshape-install.sh vagrant realease-1.1
#   geoshape-install.sh 1.x       // example of using a branch to essentially get the 1.1 'snapshot' as opposed to an actual release
#   geoshape-install.sh 0e43522   // example of using a commit id to get a 'snapshot' as opposed to an actual release


if [ "$1" = "vagrant" ];
then
  GEOSHAPE_USING_VAGRANT=true
  GEOSHAPE_VERSION="$2"
elif [ "$2" = "vagrant" ];
then
  GEOSHAPE_USING_VAGRANT=true
  GEOSHAPE_VERSION="$1"
else
  GEOSHAPE_VERSION="$1"
fi

if [ -z "$GEOSHAPE_VERSION" ];
then
  echo 'geoshape version not specified, will use latest release.'
fi

echo GEOSHAPE_USING_VAGRANT: ${GEOSHAPE_USING_VAGRANT}
echo GEOSHAPE_VERSION: ${GEOSHAPE_VERSION}


# install curl
apt-get install curl -y

# install rvm
gpg --keyserver hkp://keys.gnupg.net --recv-keys D39DC0E3
curl -L https://get.rvm.io | bash -s stable

# activate the correct rvm environment
source /usr/local/rvm/scripts/rvm

# get latest rvm
rvm get stable

# install ruby, my machine has this and things work
rvm list known
rvm install ruby-2.0.0-p353  # tyler uses 193
rvm --default use 2.0.0-p353
ruby -v # will show which version is being used


# install git
apt-get install -y git

# Pull rogue-chef-repo if it doesn't already exist on the VM.
# We do this so we can execute geoshape-install from a Vagrantfile and
# without a Vagrantfile.

cd /opt
if [ -d rogue-chef-repo ];
then
  cd rogue-chef-repo
else
  git clone https://github.com/ROGUE-JCTD/rogue-chef-repo.git
  cd rogue-chef-repo
fi

if [ -z "$GEOSHAPE_VERSION" ];
then
  # discover the latest release tag
  RELEASE_TAGS=(`git tag`)
  echo 'release tags: '
  echo "${RELEASE_TAGS[@]}"
  # sort the list of branches that had '.' in them such that index 0 is the largest one
  RELEASE_TAGS_SORTED=($(printf '%s\n' "${RELEASE_TAGS[@]}"|sort -r))
  GEOSHAPE_VERSION=${RELEASE_TAGS_SORTED[0]}
  echo '----[ discovered latest release version: '${GEOSHAPE_VERSION}
fi

git checkout ${GEOSHAPE_VERSION}

bundle install
berks install
cd ..

# Setup Chef Run folder
# if dna.json is in /opt/chef-run, move it out, then run the following, then put it back
# Also remove the other dna files that ware aren't using for this setup.

if [ -f chef-run/dna.json ];
then
echo "Copying existing dna.json"
cp chef-run/dna.json ./dna-copy.json
cp -r /opt/rogue-chef-repo/solo/* chef-run/
cp dna-copy.json chef-run/dna.json
rm dna-copy.json
rm chef-run/dna_database.json
rm chef-run/dna_application.json
cd chef-run
else
echo "Using default dna.json"
mkdir chef-run
cp -r /opt/rogue-chef-repo/solo/* chef-run/
rm chef-run/dna_application.json
rm chef-run/dna_database.json
cd chef-run
# Edit dna.json to use correct FQDN… Note: update the url to your server’s url’. If there is no fully qualified domain name, you can simply remove the line from the dna file
sed -i 's/fqdn/fqdn-ignore/g' dna.json
# if vagrant is specified, add "vagrant":true
if [ "$1"  = "vagrant" ];
then
echo "Vagrant specified..."
sed -i '2 i\
\  "vagrant": true,
' dna.json
fi
fi

# Change username referenced in provision.sh to correct user if the user on the box is not ‘rogue’ Note: manually view provision.sh and change the user to rogue

chmod 755 *.sh

# to install latest rogue run this .sh file. if you remove the /var/lib/geoserver_data folder, it will download it again. To keep your data, just leave the folder as is and the script will not pull down the basic data folder
./geoshape-upgrade.sh ${GEOSHAPE_VERSION} silent
