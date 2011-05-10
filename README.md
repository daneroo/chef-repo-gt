# Gitorious Branch Chef Repo
This repo was cloned from Opscode's `https://github.com/opscode/chef-repo.git`

## Todo
Chef needs to at 10.0, and rvm installation interferes with recipe installation on ec2.

## Setup
Follwing [Getting Started](http://help.opscode.com/kb/start/2-setting-up-your-user-environment) instructions on the opscode site.  
Keeping validation/user pems in `~/.chef`.
`knife.rb` is in this repo : `<here>/.chef/knife.rb`

Importing a cookbook with `knife cookbook site vendor getting-started` now creates a vendor traking branch per cookbook. This was not the cas when the first three cookbooks when the first three cookbooks were imported: `apache2,apt,chef-client`, perhaps they should be re-imported.

## Using encrypted Data Bags
This allows encryption of Data Bags using a shared sekret. We do need a way to transport the shared sekret to the bootstrapping client. One idea is to __use__ the already transported (temporary) `validator.pem`.

    DBAGSECRET=`shasum  ~/.chef/imetrical-validator.pem |awk '{print $1}'`
    knife data bag create -s "$DBAGSECRET" crypted smtprelay
    knife data bag show -s "$DBAGSECRET" crypted smtprelay
    knife data bag edit -s "$DBAGSECRET" crypted smtprelay

To use this in a recipe, (try in attibutes also). The secret if omited is read from

    # look for secret in file pointed to by encrypted_data_bag_secret config.
    # If not set explicity use default of /etc/chef/encrypted_data_bag_secret
    smtp_creds = Chef::EncryptedDataBagItem.load("crypted", "smtprelay", [secret])
    smtp_creds["username"] # will be decrypted
    smtp_creds["password"] # will be decrypted

This could be initialzed in the recipe with the (transformed) chef validation key, 
`Chef::Config[:validation_key]` before it is removed!

    execute "update_databag_sekret" do
      command "shasum  #{Chef::Config[:validation_key]} |awk '{print $1}' >#{Chef::Config[:encrypted_data_bag_secret]}"
      action :nothing
      only_if { 
          !::File.exists?(Chef::Config[:encrypted_data_bag_secret]) &&
          ::File.exists?(Chef::Config[:validation_key]) }
    end
    
## Adding swap on ec2

    dd if=/dev/zero of=/mnt/512Mb.swap bs=1M count=512
    chmod 600 /mnt/512Mb.swap
    mkswap /mnt/512Mb.swap
    swapon /mnt/512Mb.swap
    # then add thi to /etc/fstab, to  make permanent
    # /mnt/512Mb.swap  none  swap  sw  0 0
        
## chef-client under rvm
After rvm ruby is installed.. chef-client stops working !

    sudo gem install bundler chef ohai mysql --no-ri --no-rdoc

## Uploading a recipe
This is how to upload/update a recipe on chef server

    knife cookbook upload ekoform

## Reinitializing all cookbooks

    knife cookbook bulk delete ".+"
    knife cookbook upload -a

## Connecting to EC2 with `knife`
The local `<this_dir>/.chef/knife.rb` set up the defaults for `knife` operation.

*   Chef Server credentials (point to `~/.chef/xxx.pem` files)
*   EC2 credentials (point to `~/.chef/daneroo-ec2-aws*.txt` files)

Example commands:

    # list instances on EC2 (validates EC2 creds)
    knife ec2 server list

    # create an instance on EC2
    #   ami-3e02f257 is lucid EBS-boot 32 bit us-east-1
    knife ec2 server create  -r 'mygitorious' --node-name ec2-gitorious --flavor t1.micro --identity-file ~/.ssh/hello-aws-key.pem --image ami-3e02f257 --groups test-hello --ssh-key hello-key --ssh-user ubuntu

    # add a recipe to the run_list
    knife node run_list add ec2-ekoform 'recipe[apt]'
    
    # remove a recipe from the run_list
    knife node run_list remove nutest-box.vagrant.com 'recipe[apt]'
    
    # connect to to the instance by ssh
    # chmod 0600 ~/.ssh/hello-aws-key.pem
    ssh -i ~/.ssh/hello-aws-key.pem ubuntu@ec2-50-16-140-26.compute-1.amazonaws.com
        
## Vendor/Upstream tracking
Trying out the verdor tracking pattern:

    git remote add upstream https://github.com/opscode/chef-repo.git
    git fetch upstream
    git branch --track upstream upstream/master
    # then when you run
    git pull upstream master

It will automatically fetch from 'upstream' remote and merge 'upstream/master' into your local 'upstream' branch. Finally you can pull the upstream changes into master with:

    git merge upstream    

# Original README

## Overview

Every Chef installation needs a Chef Repository. This is the place where cookbooks, roles, config files and other artifacts for managing systems with Chef will live. We strongly recommend storing this repository in a version control system such as Git and treat it like source code.

While we prefer Git, and make this repository available via GitHub, you are welcome to download a tar or zip archive and use your favorite version control system to manage the code.

## Repository Directories

This repository contains several directories, and each directory contains a README file that describes what it is for in greater detail, and how to use it for managing your systems with Chef.

* `certificates/` - SSL certificates generated by `rake ssl_cert` live here.
* `config/` - Contains the Rake configuration file, `rake.rb`.
* `cookbooks/` - Cookbooks you download or create.
* `data_bags/` - Store data bags and items in .json in the repository.
* `roles/` - Store roles in .rb or .json in the repository.

## Rake Tasks

The repository contains a `Rakefile` that includes tasks that are installed with the Chef libraries. To view the tasks available with in the repository with a brief description, run `rake -T`.

The default task (`default`) is run when executing `rake` with no arguments. It will call the task `test_cookbooks`.

The following tasks are not directly replaced by knife sub-commands.

* `bundle_cookbook[cookbook]` - Creates cookbook tarballs in the `pkgs/` dir.
* `install` - Calls `update`, `roles` and `upload_cookbooks` Rake tasks.
* `ssl_cert` - Create self-signed SSL certificates in `certificates/` dir.
* `update` - Update the repository from source control server, understands git and svn.

The following tasks duplicate functionality from knife and may be removed in a future version of Chef.

* `metadata` - replaced by `knife cookbook metadata -a`.
* `new_cookbook` - replaced by `knife cookbook create`.
* `role[role_name]` - replaced by `knife role from file`.
* `roles` - iterates over the roles and uploads with `knife role from file`.
* `test_cookbooks` - replaced by `knife cookbook test -a`.
* `test_cookbook[cookbook]` - replaced by `knife cookbook test COOKBOOK`.
* `upload_cookbooks` - replaced by `knife cookbook upload -a`.
* `upload_cookbook[cookbook]` - replaced by `knife cookbook upload COOKBOOK`.

## Configuration

The repository uses two configuration files.

* config/rake.rb
* .chef/knife.rb

The first, `config/rake.rb` configures the Rakefile in two sections.

* Constants used in the `ssl_cert` task for creating the certificates.
* Constants that set the directory locations used in various tasks.

If you use the `ssl_cert` task, change the values in the `config/rake.rb` file appropriately. These values were also used in the `new_cookbook` task, but that task is replaced by the `knife cookbook create` command which can be configured below.

The second config file, `.chef/knife.rb` is a repository specific configuration file for knife. If you're using the Opscode Platform, you can download one for your organization from the management console. If you're using the Open Source Chef Server, you can generate a new one with `knife configure`. For more information about configuring Knife, see the Knife documentation.

http://help.opscode.com/faqs/chefbasics/knife

## Next Steps

Read the README file in each of the subdirectories for more information about what goes in those directories.
