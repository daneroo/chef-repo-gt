#
# Cookbook Name:: users
# Recipe:: sysadmins
#
# Copyright 2009-2011, Opscode, Inc.
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

sysadmin_group = Array.new

if Chef::Config.solo
  users = node[:users][:sysadmins]
else
  users = search(:users, 'groups:sysadmin')
end

users.each do |u|
  sysadmin_group << u['id']

  if node[:apache] and node[:apache][:allowed_openids]
    Array(u['openid']).compact.each do |oid|
      node[:apache][:allowed_openids] << oid unless node[:apache][:allowed_openids].include?(oid)
    end
  end

  home_dir = "/home/#{u['id']}"

  # fixes CHEF-1699
  ruby_block "reset group list" do
    block do
      Etc.endgrent
    end
    action :nothing
  end

  if !u['create_group'].nil? && u['create_group'] == true
    create_group = true
  else
    create_group = false
  end

  if create_group
    group u['id'] do
      gid u['uid'].to_i
    end
  end

  user u['id'] do
    uid u['uid']
    if create_group
      gid u['id']
    else
      gid u['gid']
    end
    shell u['shell']
    comment u['comment']
    supports :manage_home => true
    home home_dir
    notifies :create, "ruby_block[reset group list]", :immediately
  end

  directory "#{home_dir}" do
    owner u['id']
    if create_group
      group u['id']
    else
      group u['gid'] || u['id']
    end
    mode "2755"
  end

  directory "#{home_dir}/.ssh" do
    owner u['id']
    if create_group
      group u['id']
    else
      group u['gid'] || u['id']
    end
    mode "0700"
  end

  template "#{home_dir}/.ssh/authorized_keys" do
    source "authorized_keys.erb"
    owner u['id']
    if create_group
      group u['id']
    else
      group u['gid'] || u['id']
    end
    mode "0600"
    variables :ssh_keys => u['ssh_keys']
  end
end

group "sysadmin" do
  gid 2300
  members sysadmin_group
end
