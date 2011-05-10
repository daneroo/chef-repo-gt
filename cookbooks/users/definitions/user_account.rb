#
# Cookbook Name:: users
# Definition:: user_account
# Author:: Fletcher Nichol <fnichol@nichol.ca>
#
# Copyright 2010, Fletcher Nichol
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

define :user_account, :uid => nil, :gid => nil, 
    :shell => "/bin/bash", :comment => nil, :create_group => true,
    :ssh_keys => [], :enable => true do

  home_dir = "/home/#{params[:name]}"

  if params[:create_group]
    group params[:name] do
      if params[:uid]
        gid params[:uid].to_i
      end
    end
  end

  user params[:name] do
    if params[:uid]
      uid params[:uid]
    end
    if params[:create_group]
      gid params[:name]
    else
      gid params[:gid]
    end
    shell params[:shell]
    if params[:comment]
      comment params[:comment]
    else
      comment params[:name]
    end
    supports :manage_home => true
    home home_dir
  end

  directory home_dir do
    owner params[:name]
    if params[:create_group]
      group params[:name]
    else
      group params[:gid] || params[:name]
    end
    mode "2755"
  end

  directory "#{home_dir}/.ssh" do
    owner params[:name]
    if params[:create_group]
      group params[:name]
    else
      group params[:gid] || params[:name]
    end
    mode "0700"
  end

  unless params[:ssh_keys].empty?
    template "#{home_dir}/.ssh/authorized_keys" do
      cookbook "users"
      source "authorized_keys.erb"
      owner params[:name]
      if params[:create_group]
        group params[:name]
      else
        group params[:gid] || params[:name]
      end
      mode "0600"
      variables :ssh_keys => params[:ssh_keys]
    end
  end

  execute "create ssh key for #{params[:name]}" do
    cwd       home_dir
    user      params[:name]
    if params[:create_group]
      group params[:name]
    else
      group params[:gid] || params[:name]
    end
    command   <<-KEYGEN
      ssh-keygen -t dsa -f #{home_dir}/.ssh/id_dsa -N '' \
        -C '#{params[:name]}@#{node[:fqdn]}'
      chmod 0600 #{home_dir}/.ssh/id_dsa
      chmod 0644 #{home_dir}/.ssh/id_dsa.pub
    KEYGEN
    creates   "#{home_dir}/.ssh/id_dsa"
  end
end

