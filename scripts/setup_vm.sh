# install curl
apt-get install curl

# install rvm 
curl -L https://get.rvm.io | bash -s stable

# run the rest of the scripts as su - (make sure the dash is present or the rvm profile will not get set)

# get latest rvm
rvm get stable

# install ruby, my machine has this and things work
rvm list known
rvm install ruby-2.0.0-p353  # tyler uses 193
rvm --default use 2.0.0-p353
ruby -v # will show which version is being used

gem install chef --version 11.10.4 --no-rdoc --no-ri --conservative
gem install solve --version 0.8.2
gem install nokogiri --version 1.6.1
gem install berkshelf --version 2.0.18 --no-rdoc --no-ri

# install git
apt-get install -y git

cd /opt
git clone https://github.com/ROGUE-JCTD/rogue-chef-repo.git

# Setup Chef Run folder
# if dna.json is in /opt/chef-run, move it out, then run the following, then put it back

if [ -f chef-run/dna.json ];
then
echo "Copying existing dna.json"
cp chef-run/dna.json ./dna-copy.json
cp -r /opt/rogue-chef-repo/solo/* chef-run/
cp dna-copy.json chef-run/dna.json
rm dna-copy.json
cd chef-run
else
echo "Using default dna.json"
mkdir chef-run
cp -r /opt/rogue-chef-repo/solo/* chef-run/
cd chef-run
# Edit dna.json to use correct FQDN… Note: update the url to your server’s url’. If there is no fully qualified domain name, you can simply remove the line from the dna file
sed -i 's/fqdn/fqdn-ignore/g' dna.json
# if vagrant is specified, add "vagrant":true
if test $1 = "vagrant"
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

sudo dpkg -i --force-overwrite /var/cache/apt/archives/libproj-dev_4.8.0-2+opengeo_amd64.deb

./provision.sh
