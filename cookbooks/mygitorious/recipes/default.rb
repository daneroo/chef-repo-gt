#
# Cookbook Name:: mygitorious
# Recipe:: default
#
# Copyright 2011, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#
# this runs apt-get update update
require_recipe "apt"
# required otherwise the mysql gem will not install
%w{ ruby1.8-dev libmysqlclient-dev }.each do |a_package|
  package(a_package).run_action(:install)
end
gem_package('mysql').run_action(:install)
# Some nice to haves - immediate
%w{ iftop curl unzip }.each do |a_package|
  package(a_package).run_action(:install)
end

execute "add-swap-space" do
  user        "root"
  group       "root"
  command     <<-CMD
    dd if=/dev/zero of=/mnt/512Mb.swap bs=1M count=512
    chmod 600 /mnt/512Mb.swap
    mkswap /mnt/512Mb.swap
    swapon /mnt/512Mb.swap
    # then add thi to /etc/fstab, to  make permanent
    # /mnt/512Mb.swap  none  swap  sw  0 0
  CMD
  only_if      <<-NOTIF
    grep "SwapTotal.*[^0-9][0-9] kB" /proc/meminfo
  NOTIF
end

#Chef::Log.info("DD-:rvmroot #{node[:rvm][:root_path]}")
#RVM::Environment does not have environment: fix
# create links /usr/local/bin/gitorious_[rake ruby gem bundle] to
# /usr/local/rvm/wrappers/ree-1.8.7-2011.03@gitorious[rake ruby gem bundle]
%w{ rake ruby gem bundle }.each do |bin|
  # e.g. gitorious_bundle
  full_bin = "#{node[:gitorious][:rvm_gemset]}_#{bin}"
  # e.g. /usr/local/bin/gitorious_bundle
  script = ::File.join(::File.dirname(node[:rvm][:root_path]), "bin", full_bin)
  # e.g. ree-1.8.7-2011.03@gitorious
  rvm_ruby = select_ruby(node[:rvm_passenger][:rvm_ruby]) + "@" + node[:gitorious][:rvm_gemset]
  # e.g. /usr/local/rvm/wrappers/ree-1.8.7-2011.03@gitorious/bundle
  full_wrapper = ::File.join(node[:rvm][:root_path], "wrappers", rvm_ruby, bin)
  Chef::Log.info("DD:create a link : #{script} to #{full_wrapper}")
  # ln -s full_wrapper script
  link script do
    to full_wrapper
  end
end  

# same for sys_stompserver
# Creating rvm_wrapper[sys_stompserver::ree-1.8.7-2011.03@stompserver]
# DD:create a link : /usr/local/bin/sys_stompserver to /usr/local/rvm/wrappers/ree-1.8.7-2011.03@stompserver/stompserver
link '/usr/local/bin/sys_stompserver' do
  to '/usr/local/rvm/wrappers/ree-1.8.7-2011.03@stompserver/stompserver'
end

ruby_block "edit etc hosts" do
  block do
    rc = Chef::Util::FileEdit.new("/etc/hosts")
    githost_full = node[:gitorious][:host]
    githost_justname = githost_full.split('.')[0]
    Chef::Log.info("DD:/etc/hosts :== #{githost_full} #{githost_justname}")    
    rc.search_file_replace_line(/^127\.0\.0\.1\s+localhost$/, "127.0.0.1\t#{githost_full} #{githost_justname} localhost")
    rc.write_file
  end
end

# this is because nginx::source starts iptables, and shuts us out!
# maybe we should use a properly configured openssh recipe.
# this was moved down becaouse /etc/iptables.d did not exist. require repie iptable might do the trick!
case node[:platform]
when "redhat","centos","debian","ubuntu"
  include_recipe "iptables"

  #if node[:nginx][:iptables_allow] == "disable", then enable false ?
  iptables_rule "port_ssh" do
    enable true
  end
end

require_recipe "mysql::server"
firstpass=true
if firstpass then
  require_recipe "rvm"
  require_recipe "rvm_passenger::#{node[:gitorious][:web_server]}"
else
  require_recipe "gitorious"
end

# These need to run after gitorious recipe, so the git user exists

if false then
  # git user runs gitorious script, cannot find ${HOME}/.rvm/scripts/rvm
  # we will link to this one: /home/git/gitorious/current/.rvmrc
  # only required for actual connections to git (thru ssh)
  %w{ /home/git/.rvm /home/git/.rvm/scripts }.each do |dir|
    directory dir do
    #  mode 0775
      owner "git"
      group "git"
      action :create
      recursive true
    end
  end
  link '/home/git/.rvm/scripts/rvm' do
    owner "git"
    group "git"
    to '/home/git/gitorious/current/.rvmrc'
  end
end

