# Gitorious Chef Repo
This repo was cloned from Opscode's `https://github.com/opscode/chef-repo.git`

## Todo
*   Chef needs to be at 10.0, for Encrypted Data Bags to work.
*   Use capistrano w/crypted pass for axial svn
*   Add swap to EC2 instance
*   Rvm installation interferes with recipe installation on ec2 (for girotious).
*   Add an AMI instance on S3, to speed up install, perhaps solve bootstrapping problems

## Setup
Following [Getting Started](http://help.opscode.com/kb/start/2-setting-up-your-user-environment) instructions on the opscode site.  
Keeping validation/user pems in `~/.chef`.
`knife.rb` is in this repo : `<here>/.chef/knife.rb`

Importing a cookbook with `knife cookbook site vendor getting-started` now creates a vendor traking branch per cookbook. This was not the cas when the first three cookbooks when the first three cookbooks were imported: `apache2,apt,chef-client`, perhaps they should be re-imported.

## Using encrypted Data Bags
This allows encryption of Data Bags using a shared sekret. We do need a way to transport the shared sekret to the bootstrapping client. One idea is to __use__ the already transported (temporary) `validator.pem`.

    DBAGSECRET=`shasum  ~/.chef/imetrical-validator.pem |awk '{print $1}'`
    export EDITOR='mate -w'
    knife data bag create -s "$DBAGSECRET" crypted smtprelay
    knife data bag show -s "$DBAGSECRET" crypted smtprelay
    knife data bag edit -s "$DBAGSECRET" crypted smtprelay

To use this in a recipe, (try in attibutes also). The secret if omited is read from

    # look for secret in file pointed to by encrypted_data_bag_secret config.
    # If not set explicity use default of /etc/chef/encrypted_data_bag_secret
    smtp_creds = Chef::EncryptedDataBagItem.load("crypted", "smtprelay", [secret])
    smtp_creds["username"] # will be decrypted
    smtp_creds["password"] # will be decrypted

To check the encrypted version into version control, we could use:

    knife data bag show  crypted svncreds --format json > data_bags/crypted/svncreds.json
    knife data bag from file crypted data_bags/crypted/svncreds.json

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

    knife cookbook upload mygitorious

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

