current_dir = File.dirname(__FILE__)
dotchef_dir = "#{ENV['HOME']}/.chef"

log_level                :info
log_location             STDOUT
node_name                "daneroo"
client_key               "#{dotchef_dir}/daneroo.pem"

#validation_client_name   "imetrical-validator"
#validation_key           "#{dotchef_dir}/imetrical-validator.pem"
#chef_server_url          "https://api.opscode.com/organizations/imetrical"

validation_client_name   "axial-validator"
validation_key           "#{dotchef_dir}/axial-validator.pem"
chef_server_url          "https://api.opscode.com/organizations/axial"

cache_type               'BasicFile'
cache_options( :path => "#{dotchef_dir}/checksums" )
cookbook_path            ["#{current_dir}/../cookbooks"]

# EC2: keep this data secret w/ ENV var or in a file in ~/.chef
#knife[:aws_access_key_id]     = "#{ENV['AWS_ACCESS_KEY_ID']}"
#knife[:aws_secret_access_key] = "#{ENV['AWS_SECRET_ACCESS_KEY']}"
knife[:aws_access_key_id]     = `cat #{dotchef_dir}/daneroo-ec2-aws_access_key_id.txt`
knife[:aws_secret_access_key] = `cat #{dotchef_dir}/daneroo-ec2-aws_secret_access_key.txt`
