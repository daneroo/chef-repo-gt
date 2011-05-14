
# prove we can use a sekret
# note the validation.pem which is bootstraped by knife has an extra \n!
require 'digest/sha1'; 
Chef::Log.info("DD:validation_key #{Chef::Config[:validation_key]}")
vpem=%x/head -c 1678 #{Chef::Config[:validation_key]}/; 
secret=Digest::SHA1.hexdigest(vpem)
Chef::Log.info("DD:DBAGSECRET #{secret}")
smtp_creds = Chef::EncryptedDataBagItem.load("crypted", "smtprelay", secret)
Chef::Log.info("DD:decrypted username #{smtp_creds["username"]}")

 # will be decrypted


set[:mysql][:server_root_password] = 'mysekret'

#set[:rvm][:default_ruby] = "ruby-1.9.2-p180"
set[:rvm][:default_ruby] = "ree-1.8.7-2011.03"
#set[:rvm][:rubies] = ["ree-1.8.7-2011.03"]

set[:iptables][:status] = "enable"

set[:nginx][:iptables_ports] = [ 80, 443 ]
set[:nginx][:extra_configure_flags] =  [ "--with-http_sub_module" ]

set[:gitorious][:host] =  'gitorious.local'
set[:gitorious][:db][:password] =  'gitsekret'
set[:gitorious][:notification_emails] =  "daniel.lauzon@gmail.com"
set[:gitorious][:support_email] =  "daniel.lauzon@gmail.com"
set[:gitorious][:mailer][:delivery_method] =  "smtp"
set[:gitorious][:smtp][:tls] =  "true"
set[:gitorious][:smtp][:address] =  "smtp.gmail.com"
set[:gitorious][:smtp][:port] =  "587"
set[:gitorious][:smtp][:domain] =  "gmail.com"
set[:gitorious][:smtp][:username] =  smtp_creds["username"]
set[:gitorious][:smtp][:password] =  smtp_creds["password"]
set[:gitorious][:smtp][:authentication] =  "plain"

Chef::Log.info("DD:decrypted password #{node[:gitorious][:smtp][:password]}")
