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

node['get-gitrepos']['repos'].each do |repoSpec|
    
  repoSpec.each do |repoName, repo|
    
    getHomeCmd = Mixlib::ShellOut.new("useradd -D|grep HOME|cut -d '=' -f 2")
    getHomeCmd.run_command

    homeDir = getHomeCmd.stdout.chomp
    
    gitUserName = repo['user']['username']
    userHomePath = "#{homeDir}/#{gitUserName}"
    
    user gitUserName do
        action   :create
        username gitUserName
        password repo['user']['password']
        comment  repo['user']['fullname']
        home     userHomePath
        shell    repo['user']['shell'] || '/bin/bash'
    end
    
    directory userHomePath do
        owner gitUserName
        group gitUserName
        recursive true
        action :create
    end
    
    directory "#{userHomePath}/workspace" do
        owner gitUserName
        group gitUserName
        recursive true
        action :create
    end
    
    directory "#{userHomePath}/workspace/tycho" do
        owner gitUserName
        group gitUserName
        recursive true
        action :create
    end

    group "tsusers" do
        action :create
    end
    
    group "tsusers" do
        action :modify
        members gitUserName
        append  true
    end
 
    xSessionFile = "#{userHomePath}/.xsession"
    
    file xSessionFile do
        owner gitUserName
        group gitUserName
        mode 0644
        content repo['user']['xsession']
        
        action :create_if_missing
    end
    
    destPath = repo['destination'].sub( /~/, "#{homeDir}/" )
    
    directory destPath do
        owner gitUserName
        group gitUserName
        recursive true
        action :create
    end

    destPath = ::File.expand_path( destPath )

    git_key = Chef::EncryptedDataBagItem.load( "private_keys", "git_ssh" )
    
    file "#{userHomePath}/.ssh/id_rsa" do
        content git_key['private']
    end

    git destPath do
        repository repo['url']
        reference  repo['remote-branch-name'] || 'master'
        revision   repo['revision'] || 'HEAD'
        checkout_branch repo['local-branch-name']
        
        action :checkout
        
        ssh_wrapper "ssh -i #{userHomePath}/.ssh/id_rsa"
    end
    
    log "message" do
        message "Cloned #{repoName} for user #{gitUserName} into #{destPath}."
        level :info
    end
  end
end