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

users_manage "devops" do
  action :create
end

node['get-gitrepos']['repos'].each do |repoSpec|
    
  repoSpec.each do |repoName, repo|
    
    getHomeCmd = Mixlib::ShellOut.new("useradd -D|grep HOME|cut -d '=' -f 2")
    getHomeCmd.run_command

    homeDir = getHomeCmd.stdout.chomp
    
    gitUserName = repo['user']['username']
    userHomePath = File.join( homeDir, gitUserName )
    
    if ( !Pathname.new( userHomePath ).directory? )
        
        log "message" do
            message "user #{gitUserName} missing from data_bags/users or not specified to be in devops group."
            level :warn
        end
        
        next
    end
    
    sudo gitUserName do
        user gitUserName
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
    
    destPath = Pathname.new( repo['destination'].sub( /~/, "#{homeDir}/" ) )
    
    destPath.descend{ |dir|
    
        directory dir.to_s do
            owner gitUserName
            group gitUserName
            
            action :create
            
            not_if { dir.exist?() }
        end
        
        log "message" do
            message "Created #{dir} for #{gitUserName} only if necessary."
            level :info
        end
    }

    git_key = Chef::EncryptedDataBagItem.load( "private_keys", "git_ssh" )

    directory "#{userHomePath}/.ssh" do
        owner gitUserName
        group gitUserName
        mode 0700
        recursive true
        
        action :create
    end
    
    file "#{userHomePath}/.ssh/config" do
        owner gitUserName
        group gitUserName
        mode 0600
   
        content <<-EOT
Host *
  StrictHostKeyChecking no
  IdentityFile #{userHomePath}/.ssh/id_rsa
  IdentitiesOnly yes
EOT
    end
    
    file "#{userHomePath}/.ssh/id_rsa" do
        owner gitUserName
        group gitUserName
        mode 0600
        
        content git_key['private']
    end
    
    file "#{userHomePath}/.ssh/id_rsa.pub" do
        owner gitUserName
        group gitUserName
        mode 0644
        
        content git_key['public']
    end
    
# add several likely SSH hosts with git repositories
    ssh_known_hosts_entry 'github.com'
    ssh_known_hosts_entry 'bitbucket.org'

# in the context of the requested user, clone, checkout, and branch the repo
    execute "as user #{gitUserName}, clone #{repo['url']}" do
        cwd destPath.to_s
        user gitUserName
        group gitUserName
        
        command "git clone -n #{repo['url']} #{destPath}"
        
        not_if { File.exists?( File.join( destPath, ".git" ) ) }
    end
    
    execute "as user #{gitUserName}, checkout #{repo['remote-branch-name'] || 'master'} from #{repo['url']}" do
        cwd destPath.to_s
        user gitUserName
        group gitUserName
        
        command "git checkout #{repo['remote-branch-name'] || 'master'}"
    end
    
    execute "as user #{gitUserName}, switch to branch #{repo['local-branch-name']}" do
        cwd destPath.to_s
        user gitUserName
        group gitUserName
        
        command "git checkout #{repo['local-branch-name']}"
        only_if "git show-branch #{repo['local-branch-name']}", :cwd => destPath.to_s, :user => gitUserName
    end
    
    execute "as user #{gitUserName}, create branch of #{repo['url']} as #{repo['local-branch-name']}" do
        cwd destPath.to_s
        user gitUserName
        group gitUserName
        
        command "git checkout -b #{repo['local-branch-name']} #{repo['revision'] || 'HEAD'}"
        not_if "git show-branch #{repo['local-branch-name']}", :cwd => destPath.to_s, :user => gitUserName
    end

    log "message" do
        message "Cloned #{repoName} for user #{gitUserName} into #{destPath}."
        level :info
    end
  end
end