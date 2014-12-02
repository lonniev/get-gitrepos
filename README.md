get-gitrepos Cookbook
=============
Clones one or more git repositories into the specified user's specified directory of git repositories

Attributes
----------
*

Usage
-----

Include chef.add_recipe "get-gitrepos" to your Vagrantfile.

A variety of configuration has to be performed to be able to access ssh-keyed private git repositories. Once all of this is done, your recipes can retrieve such repositories without any interactive prompts to the user.

Perform these steps:

* begin with an ssh key that lacks a passphrase
   * (_when a key with a passphrase is used, either the openssl or the gnome-keyring ssh-agent will demand to interactively be given the passphrase at least once before access to the ssh private key is granted_)
```bash
$ssh-keygen
generating public/private rsa key pair.
Enter file in which to save the key (~/.ssh/id_rsa): <enter>
Enter passphrase (empty for no passphrase): <enter>
Enter same passphrase again: <enter>
Your identification has been saved in ~/.ssh/id_rsa.
Your public key has been saved in ~/.ssh/id_rsa.pub.
```
* place both the private (e.g. id_rsa) and the public (e.g. id_rsa.pub) files in the user's ~/.ssh directory
* paste the public key into the Git repository for the sought private access
```bash
$cat ~/.ssh/id_rsa.pub | pbcopy
```
  * then visit bitbucket.org or github.com and register a new SSH key for the repository, pasting in the public key
* assure that owner and group permissions are correct for each .ssh file:
```bash
  $chown -R user:user ~/.ssh
  $chmod 0600 ~/.ssh/id_rsa
  $chmod 0644 ~/.ssh/id_rsa.pub
  $chmod 0700 ~/.ssh
  $chmod 0600 ~/.ssh/config
```
* automatically enter new hosts into the the user's ~/.ssh/known_hosts file without interactive approval and force ssh to use only the provided Identity File(s) and not anything previously cached by appending the following to the ~/.ssh/config file:
```bash
Host *
  StrictHostKeyChecking no
  IdentityFile #{userHomePath}/.ssh/id_rsa
  IdentitiesOnly yes
```
* use the `ssh_known_hosts` recipe and its `ssh_known_hosts_entry` LWRP to add known_host entries for github.com and bitbucket.org (and any others you may need)
```ruby
ssh_known_hosts_entry 'github.com'
ssh_known_hosts_entry 'bitbucket.org'
```
* use the `execute` resource to clone, branch, and checkout to private repository, providing the `user` attribute to run as the end user, using the ssh configuration created for that user:
```ruby
    execute "as user #{gitUserName}, clone #{repo['url']}" do
        cwd destPath
        user gitUserName
        group gitUserName
        
        command "git clone -n #{repo['url']} #{destPath}"
        
        not_if { File.exists?( File.join( destPath, ".git" ) ) }
    end
    
    execute "as user #{gitUserName}, checkout #{repo['remote-branch-name'] || 'master'} from #{repo['url']}" do
        cwd destPath
        user gitUserName
        group gitUserName
        
        command "git checkout #{repo['remote-branch-name'] || 'master'}"
    end
    
    execute "as user #{gitUserName}, branch #{repo['url']} as repo['local-branch-name']" do
        cwd destPath
        user gitUserName
        group gitUserName
        
        command "git checkout -b #{repo['local-branch-name']} #{repo['revision'] || 'HEAD'}"
    end
```
To securely share the ssh private and public keys with vagrant and chef-solo so that the target VM has the suitable ssh files, store the information in an encrypted data bag. When running just chef-solo within the vagrant session without the infrastructure of a full Chef Server and knife deployment, getting the encrypted data bag constructed can be challenging. Here's one way to do it:
* create the ssh private and public keys as stated above with ssh-keygen
* create a chef encrypted_data_bag_secret key in ~/.chef using openssl
  * (_this creates a random base64-encoded 512-bit key with the sequences of carriage-return, newline stripped out and stores it as your personal databag encryption key_)
```bash
openssl rand -base64 512 | tr -d '\r\n' > ~/.chef/encrypted_data_bag_secret
```
* create the directories in the vagrant's host directory to store the data bag
```bash
$cd <host_vagrant_dir>
$mkdir -p ./bags/private_keys
```
* tell the chef provisioner within the Vagrantfile where to find the key and the bag(s):
```ruby
      chef.encrypted_data_bag_secret_key_path = "~/.chef/encrypted_data_bag_secret"

      chef.cookbooks_path = "./cookbooks"
      chef.roles_path = "./roles"
      chef.data_bags_path = "./bags"
```
* create the plaintext data bag as a JSON file with the contents of the private and public ssh keys as properties:
```bash
ruby -rjson -e 'puts JSON.generate({"id" => "git_ssh", "public" => File.read("~/.ssh/bitbucket_sodius_id_rsa.pub"), "private" => File.read("~/.ssh/bitbucket_sodius_id_rsa")})' > plaintext_bag.json
```
* use `encrypt_data_bag.rb` from Gist https://gist.github.com/vitobotta/6279094 to encrypt the plaintext bag without having to install Chef Server and knife:
```bash
$./encrypt_data_bag.rb plaintext_bag.json bags/private_keys/git_ssh.json ~/.chef/encrypted_data_bag_secret
```
* obtain the decrypted plaintext versions of the private and public keys with the Chef EncryptedDataBagItem methods in your chef recipes like this:
```ruby
git_key = Chef::EncryptedDataBagItem.load( "private_keys", "git_ssh" )
```
* finally, have your recipe create the ~/.ssh identity files on the target vagrant with the following `file` resource statements:
```ruby
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
```
Of course, as is often the case, there is probably some elusive way to do all this with just a few lines of chef DSL. Should you have a more efficient way to achieve the goal, share that with our community. (My apologies to @patrickheeney for hijacking his Issues forum to work this issue; it simply is very similar to the thread that was already here.)

Contributing
------------
To Contribute

1. Fork the repository on Github
2. Create a named feature branch (like `add_component_x`)
3. Write you change
4. Write tests for your change (if applicable)
5. Run the tests, ensuring they all pass
6. Submit a Pull Request using Github

License and Authors
-------------------
Authors: Lonnie VanZandt <lonniev@gmail.com>
