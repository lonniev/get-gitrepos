#
# Cookbook Name:: get-gitrepos
# Recipe:: default
#
# Copyright 2014, Lonnie VanZandt
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

node['get-gitrepos']['repos'].each do |repo|
    
    user repo['user'] do |aUser|
        action :create
        username aUser['username']
        comment aUser['fullname']
        supports :manage_home=>true
        shell aUser['shell'] || '/bin/bash'
    end
    
    execute "force new password for user" do
        command "chage -d 0 " + repo['user']['username']
    end
    
    git repo['destination'] do
        repository repo['url']
        reference  repo['revision'] || 'master'
        user       repo['user'] || 'username'
        action :sync
    end
end