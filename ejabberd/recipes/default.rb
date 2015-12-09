#bash "add erlang source to apt sources" do
#  code <<-EOH
#    echo 'deb http://packages.erlang-solutions.com/debian precise contrib' >> /etc/apt/sources.list
#    wget -O - http://packages.erlang-solutions.com/debian/erlang_solutions.asc | apt-key add -
#  EOH
#  not_if "grep asdfsdf /etc/apt/sources.list"
#end

bash "update apt" do
  code "apt-get update"
end

package "esl-erlang" do
  action :install
end

package "ejabberd" do
  action :install
end

package "nginx"
  action :install
end

service "nginx" do
  action :start
end

group 'ejabberd'
user 'ejabberd' do
  group 'ejabberd'
end

[
  "build-essential",
  "libssl-dev",
  "libexpat1-dev",
  "zlib1g-dev",
].each do |pkg|
  package pkg do
    action :install
  end
end

package "git-core" do
  action :install
end

# bash "install rebar" do
#   code <<-EOH
#     cd ~/
#     git clone git://github.com/rebar/rebar.git
#     cd rebar/
#     ./bootstrap
#     cp rebar /usr/bin/
#   EOH
# end
#
#
# bash "compile ejabberd" do
#   code <<-EOH
#     cd ~/
#     git clone https://github.com/processone/ejabberd.git ejabberd
#     cd ejabberd
#     git checkout -b 2.1.x origin/2.1.x
#     cd src
#     ./configure --enable-odbc --prefix=/usr --enable-user=ejabberd --sysconfdir=/etc --localstatedir=/var --libdir=/usr/lib
#     make install
#   EOH
# end
#
#


bash "install ejabberd postgres" do
  code <<-EOH
    cd ~/
    git clone https://github.com/processone/pgsql
    cd pgsql/
    make
    cp ebin/* /usr/lib/ejabberd/ebin/
  EOH
end




bash "install mod_admin_extra" do
  code <<-EOH
    cd ~
    git clone git://github.com/processone/ejabberd-contrib.git
    cd ejabberd-contrib
    git checkout 2.1.x
    cd mod_admin_extra
    ./build.sh
    cp ebin/* /usr/lib/ejabberd/ebin
  EOH
end




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
