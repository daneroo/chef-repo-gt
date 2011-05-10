set[:apache][:listen_ports] = [ "80","81" ]

require 'digest/sha1';
#Chef::Log.info("DD:validation_key #{Chef::Config[:validation_key]}")
vpem=%x/cat #{Chef::Config[:validation_key]}/;
secret=Digest::SHA1.hexdigest(vpem)
Chef::Log.info("DD:DBAGSECRET #{secret}")
svn_creds = Chef::EncryptedDataBagItem.load("crypted", "svncreds", secret)
Chef::Log.info("DD:decrypted username #{svn_creds["username"]}")

