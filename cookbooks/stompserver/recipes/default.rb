#
# Author:: Joshua Timberman <joshua@opscode.com>
# Cookbook Name:: stompserver
# Recipe:: default
#
# Copyright 2008-2009, Opscode, Inc
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

include_recipe "packages"
include_recipe "rvm"

if platform?("centos","redhat","debian","ubuntu") and dist_only?
  package value_for_platform(
    "centos" => { "default" => "rubygem-stompserver" },
    "redhat" => { "default" => "rubygem-stompserver" },
    "debian" => { "default" => "stompserver" },
    "ubuntu" => { "default" => "stompserver" }
  )

  service "stompserver" do
    supports [ :restart, :reload, :status ]
    action [ :enable, :start ]
  end

  return
end

include_recipe "runit"

rvm_ruby = node[:stompserver][:rvm_ruby] || "#{node[:rvm][:default_ruby]}@stompserver"

rvm_gem "stompserver" do
  ruby_string rvm_ruby
end

rvm_wrapper "sys" do
  ruby_string rvm_ruby
  binary      "stompserver"
end

runit_service "stompserver"
