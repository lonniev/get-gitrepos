#
# Cookbook Name:: get-gitrepos
# Recipe:: default
#
# Copyright 2014, Lonnie VanZandt lonniev@gmail.com
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

default['get-gitrepos']['repos'] =
[
  {
     'tycho-demo' =>
     {
         'user'=> {
             'fullname' => 'Ima Coder',
             'username' => 'icoder',
             'password' => '$1$AjPVIlOd$.T6f5fjD3x1su.bNB2SDQ.',
             'shell'    => '/bin/bash',
             'xsession' => 'xfce4-session'
         },
         
         'destination' => '~icoder/workspace/tycho/org.eclipse.tycho-demo',
         'url' => 'git://git.eclipse.org/gitroot/tycho/org.eclipse.tycho-demo.git',
         'remote-branch-name' => 'master',
         'revision' => 'HEAD',
         'local-branch-name' => 'icoder_cloned_master'
     }
  }
]