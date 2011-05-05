current_dir = File.dirname(__FILE__)
dotchef_dir = "#{ENV['HOME']}/.chef"
log_level                :info
log_location             STDOUT
node_name                "daneroo"
client_key               "#{dotchef_dir}/daneroo.pem"
validation_client_name   "imetrical-validator"
validation_key           "#{dotchef_dir}/imetrical-validator.pem"
chef_server_url          "https://api.opscode.com/organizations/imetrical"
cache_type               'BasicFile'
cache_options( :path => "#{dotchef_dir}/checksums" )
cookbook_path            ["#{current_dir}/../cookbooks"]
