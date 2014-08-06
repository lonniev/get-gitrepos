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

node['get-gitrepos']['repos'].each do |reponame, repo|
    
    gitUserName = repo['user']['username']
    userHomePath = "~" << gitUserName
    
    user gitUserName do
        action :create
        username gitUserName
        password repo['user']['password']
        comment repo['user']['fullname']
        supports :manage_home=>true
        shell repo['user']['shell'] || '/bin/bash'
    end
    
    execute "check for home directory" do
        
        mkHomeDir = "mkdir -p " << userHomePath << "; chown " << gitUserName << "." << gitUserName << " " << userHomePath
        
        command mkHomeDir
        
        creates userHomePath
        not_if { ::File.exists?( userHomePath ) }
    end
    
    execute "force new password for user" do
        
        forcePasswordAge = "chage -d 0 " << gitUserName

        command forcePasswordAge
    end

    destPath = repo['destination']
    
    execute "check for destination directory" do
        
        mkDestDir = "mkdir -p " << destPath << "; chown " << gitUserName << "." << gitUserName << " " << destPath
        
        command mkDestDir
        
        creates destPath
        not_if { ::File.exists?( destPath ) }
    end

    git repo['destination'] do
        repository repo['url']
        reference  repo['revision'] || 'master'
        action :sync
    end
end