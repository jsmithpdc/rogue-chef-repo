#!/bin/bash
# exit if anything returns failure
set -e

#-- parse parameters to see if 'vagrant' and/or a second parameter have been passed in
#   if vagrant is passed in, the otehr paramt will be used as rogue version. if only one
#   param is passed in and it is not vagrant, it will be used as the rogue varions. 
#   valid usage example: 
#   setup_vm.sh 2.x
#   setup_vm.sh 2.x vagrant
#   setup_vm.sh vagrant 2.x
#   setup_vm.sh

if [ "$1" = "vagrant" ];
then
  ROGUE_USING_VAGRANT=true
  ROGUE_VERSION="$2"
elif [ "$2" = "vagrant" ];
then
  ROGUE_USING_VAGRANT=true
  ROGUE_VERSION="$1"
else
  ROGUE_VERSION="$1" 
fi

if [ -z "$ROGUE_VERSION" ];
then
  echo 'rogue version not specified, will use latest release.'
fi

echo ROGUE_USING_VAGRANT: ${ROGUE_USING_VAGRANT}
echo ROGUE_VERSION: ${ROGUE_VERSION}


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

# Pull ROGUE-CHEF-REPO if it doesn't already exist on the VM.
# We do this so we can execute setup_vm from a Vagrantfile and
# without a Vagrantfile.

cd /opt
if [ -d rogue-chef-repo ];
then
  cd rogue-chef-repo
else
  git clone https://github.com/ROGUE-JCTD/rogue-chef-repo.git
  cd rogue-chef-repo
fi

if [ -z "$ROGUE_VERSION" ];
then
  # discover the branches in the repo and use the one matching ${ROGUE_VERSION}. if it is not set, use the highest #.x branch
  BRANCHES=(`git for-each-ref --shell --count=30 refs/heads/ --format='%(refname:short)'`)
  BRANCHES_RELEASE=()

  for BRANCH in "${BRANCHES[@]}"
  do
    # consider any branch name that has a '.' in its name a potential release branch
    if [[ $BRANCH == *"."* ]]
    then
      BRANCHES_RELEASE+=("$BRANCH")
    fi
  done

  # sort the list of branches that had '.' in them such that index 0 is the largest one
  BRANCHES_RELEASE_SORTED=($(printf '%s\n' "${BRANCHES_RELEASE[@]}"|sort -r))
  #echo 'sorted release branches: '
  #echo "${BRANCHES_RELEASE_SORTED[@]}"
  ROGUE_VERSION=${BRANCHES_RELEASE_SORTED[0]}
  echo '----[ discovered rogure release version: '${ROGUE_VERSION}
fi

git checkout -b ${ROGUE_VERSION} origin/${ROGUE_VERSION}
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
./provision.sh
