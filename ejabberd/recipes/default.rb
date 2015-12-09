bash "update apt" do
  code "apt-get update"
end

[
  "build-essential",
  "libssl-dev",
  "libexpat1-dev",
  "zlib1g-dev",
  "git-core",
  "ejabberd",
  "postgresql",
  "nginx"
].each do |pkg|
  package pkg do
    action :install
  end
end


group 'ejabberd'
user 'ejabberd' do
  group 'ejabberd'
end

bash "install ejabberd postgres" do
  code <<-EOH
    cd ~/
    git clone https://github.com/processone/pgsql
    cd pgsql/
    make
    cp ebin/* /usr/lib/ejabberd/ebin/
  EOH
end




# bash "install mod_admin_extra" do
#   code <<-EOH
#     cd ~
#     git clone git://github.com/processone/ejabberd-contrib.git
#     cd ejabberd-contrib
#     git checkout 2.1.x
#     cd mod_admin_extra
#     ./build.sh
#     cp ebin/* /usr/lib/ejabberd/ebin
#   EOH
# end




template "/etc/init.d/ejabberd" do
  owner 'root'
  group 'root'
  mode 0755
  source "init.d/ejabberd.erb"
end

template "/etc/ejabberd/ejabberd.cfg" do
  source "ejabberd.cfg.erb"
  owner "ejabberd"
  variables({
    :jabber_domain      => node[:jabber_domain],
    :pgsql_hostname     => node[:pgsql_hostname],
    :pgsql_databasename => node[:pgsql_databasename],
    :pgsql_username     => node[:pgsql_username],
    :pgsql_password     => node[:pgsql_password]
  })
end

template "/etc/ejabberd/ejabberdctl.cfg" do
  source "ejabberdctl.cfg.erb"
  owner "ejabberd"
end

template "/etc/ejabberd/inetrc" do
  source "inetrc.erb"
  owner "ejabberd"
end



cookbook_file "ejabberd.example.pem" do
  path "/etc/ejabberd/ejabberd.pem"
  owner "ejabberd"
  group "ejabberd"
  mode "600"
  action :create
end


service "ejabberd" do
  action :enable
  supports :restart => true
end

service "nginx" do
  action :start
  supports :restart => true
end
