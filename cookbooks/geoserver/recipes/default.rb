tmp_geoserver_war = File.join('/tmp/', 'geoserver.war')

remote_file tmp_geoserver_war do
  source node['geoserver']['war_location']
  action :create
end

log "Downloaded geoserver"

execute "copy_geoserver_war" do 
  command "mv #{tmp_geoserver_war} #{node['tomcat']['webapp_dir']}"
  action :run
end

file File.join(node['tomcat']['webapp_dir'],"geoserver.war") do
  owner node['tomcat']['user']
  group node['tomcat']['group']
  action :touch
end

service 'tomcat' do
  action :restart
end

geoserver_data_dir = File.join(node['tomcat']['webapp_dir'],'geoserver', 'data')

# move the geoserver data dir to correct location
if not geoserver_data_dir.eql? node['geoserver']['data_dir'] and File.exists? 	geoserver_data_dir
  execute "copy geoserver data dir" do
   command "mv #{geoserver_data_dir} #{node['geoserver']['data_dir']}"
   action :run
  end
end

template File.join(node['tomcat']['webapp_dir'], 'geoserver', 'WEB-INF', 'web.xml') do
  source 'web.xml.erb'
  retry_delay 10
  retries 5
  owner node['tomcat']['user']
  group node['tomcat']['group']
end


#### Install JAI ####
jai_file = File.join(node['java']['java_home'], 'jai-1_1_3-lib-linux-amd64-jdk.bin')
jai_io_file = File.join(node['java']['java_home'], 'jai_imageio-1_1-lib-linux-amd64-jdk.bin')

remote_file  jai_file do
  source node['geoserver']['jai']['url']
  mode 755
end
  
remote_file jai_io_file do
  source node['geoserver']['jai_io']['url']
  mode 755
end

execute "fix jai" do
  cwd node['java']['java_home']
  command "sed s/+215/-n+215/ jai_imageio-1_1-lib-linux-amd64-jdk.bin > jai_imageio-1_1-lib-linux-amd64-jdk-fixed.bin"
end

# TODO Need to auto accept the JAI terms.
#execute "install_jai" do
# cwd node['java']['java_home']
# command "bash yes | ./jai-1_1_3-lib-linux-amd64-jdk.bin"
# action :run
#end

# TODO Need to auto accept the JAI IO terms.
#execute "install_jai_io" do
# cwd node['java']['java_home']
# command "bash yes | ./jai_imageio-1_1-lib-linux-amd64-jdk-fixed.bin"
# action :run
#end

service 'tomcat' do
  action :start
end

apt_repository "opengeo" do
  uri 'http://apt.opengeo.org/ubuntu'
  distribution 'lucid'
  components ['main']
  key 'http://apt.opengeo.org/gpg.key'
end

"libgdal".split.each do |pkg|
    apt_package pkg do
      action :install
    end
end

tmp_geowebcache_war = File.join('/tmp/', 'geowebcache.war')

remote_file tmp_geowebcache_war do
  source node['geoserver']['geowebcache']['url']
  action :create
end

log "Downloaded geowebcache"

execute "copy_geowebcache_war" do 
  command "mv #{tmp_geowebcache_war} #{node['tomcat']['webapp_dir']}"
  action :run
  notifies :restart, resources(:service => "tomcat")
end
