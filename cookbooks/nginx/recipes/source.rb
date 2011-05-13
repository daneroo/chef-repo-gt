#
# Cookbook Name:: nginx
# Recipe:: source
#
# Author:: Adam Jacob (<adam@opscode.com>)
# Author:: Joshua Timberman (<joshua@opscode.com>)
# Author:: Fletcher Nichol (<fnichol@nichol.ca>)
#
# Copyright 2009-2011, Opscode, Inc.
# Copyright 2010-2011, Fletcher Nichol
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

include_recipe "build-essential"

unless platform?("centos","redhat","fedora")
  include_recipe "runit"
end

packages = value_for_platform(
    ["centos","redhat","fedora"] => {'default' => ['pcre-devel', 'openssl-devel']},
    "default" => ['libpcre3', 'libpcre3-dev', 'libssl-dev']
  )

packages.each do |devpkg|
  package devpkg
end

nginx_version = node[:nginx][:version]
nginx_install = node[:nginx][:install_path]
unless node[:nginx][:extra_configure_flags].empty?
  node[:nginx][:configure_flags].push(*node[:nginx][:extra_configure_flags])
end
configure_flags = node[:nginx][:configure_flags].join(" ")
node.set[:nginx][:daemon_disable] = true

archive_cache = node[:nginx][:archive_cache]
tar_url = node[:nginx][:tar_url]

directory archive_cache do
  owner     "root"
  group     "root"
  mode      "0755"
  recursive true
end

remote_file "#{archive_cache}/nginx-#{nginx_version}.tar.gz" do
  source  tar_url
  mode    "0644"
  action  :create_if_missing
end

bash "extract_nginx_source" do
  user    "root"
  group   "root"
  cwd     archive_cache
  code    <<-EOH
    tar zxf nginx-#{nginx_version}.tar.gz
  EOH
  creates "#{archive_cache}/nginx-#{nginx_version}"
end

bash "compile_nginx_source" do
  user    "root"
  group   "root"
  cwd     archive_cache
  code    <<-EOH
    cd nginx-#{nginx_version} && ./configure #{configure_flags}
    make && make install
  EOH
  only_if do
    any_missing = false
    node[:nginx][:configure_flags].each do |flag|
      result = %x{
        if #{nginx_install}/sbin/nginx -V 2>&1 | grep -q -- "#{flag}" ; then
          echo found
        fi
      }
      any_missing = true unless result.chomp == "found"
    end
    if any_missing
      true
    else
      creates node[:nginx][:src_binary]
      false
    end
  end
end

directory node[:nginx][:log_dir] do
  mode    "0755"
  owner   node[:nginx][:user]
  action  :create
end

directory node[:nginx][:dir] do
  owner "root"
  group "root"
  mode  "0755"
end

%w{ sites-available sites-enabled conf.d }.each do |dir|
  directory "#{node[:nginx][:dir]}/#{dir}" do
    owner "root"
    group "root"
    mode "0755"
  end
end

%w{nxensite nxdissite}.each do |nxscript|
  template "/usr/sbin/#{nxscript}" do
    source "#{nxscript}.erb"
    mode "0755"
    owner "root"
    group "root"
  end
end

template "nginx.conf" do
  path "#{node[:nginx][:dir]}/nginx.conf"
  source "nginx.conf.erb"
  owner "root"
  group "root"
  mode "0644"
end

cookbook_file "#{node[:nginx][:dir]}/mime.types" do
  source "mime.types"
  owner "root"
  group "root"
  mode "0644"
end

unless platform?("centos","redhat","fedora")
  runit_service "nginx"

  service "nginx" do
    subscribes :restart, resources(:bash => "compile_nginx_source")
    subscribes :restart, resources(:template => "nginx.conf")
    subscribes :restart, resources(:cookbook_file => "#{node[:nginx][:dir]}/mime.types")
  end
else
  #install init db script
  template "/etc/init.d/nginx" do
    source "nginx.init.erb"
    owner "root"
    group "root"
    mode "0755"
  end

  #install sysconfig file (not really needed but standard)
  template "/etc/sysconfig/nginx" do
    source "nginx.sysconfig.erb"
    owner "root"
    group "root"
    mode "0644"
  end

  #register service
  service "nginx" do
    supports :status => true, :restart => true, :reload => true
    action :enable
    subscribes :restart, resources(:bash => "compile_nginx_source")
  end
end

case node[:platform]
when "redhat","centos","debian","ubuntu"
  include_recipe "iptables"

  iptables_rule "port_nginx" do
    if node[:nginx][:iptables_allow] == "disable"
      enable false
    else
      enable true
    end
  end
end

