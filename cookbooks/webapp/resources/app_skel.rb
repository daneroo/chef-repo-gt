#
# Cookbook Name:: webapp
# Resource:: app_skel
#
# Author:: Fletcher Nichol <fnichol@nichol.ca>
#
# Copyright 2010, 2011, Fletcher Nichol
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

actions :create, :delete, :disable

attribute :name,              :kind_of => String, :name_attribute => true
attribute :vhost,             :kind_of => String, :required => true
attribute :profile,           :kind_of => String, :default => "static",
  :equal_to => %w{ static rails rack php }
attribute :user,              :kind_of => String, :default => "deploy"
attribute :group,             :kind_of => String
attribute :mount_path,        :kind_of => String, :default => ""
attribute :env,               :kind_of => String
attribute :site_vars,         :kind_of => Hash

def initialize(*args)
  super
  @action = :create
end
