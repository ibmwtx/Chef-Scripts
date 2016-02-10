#
# Cookbook Name:: wtxTest1
# Recipe:: default
#
# Copyright 2014, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#
package 'ksh'
package 'bc'

directory "/home/ec2-user/temp" do
  mode 00777
  action :create
end

directory "/home/ec2-user/bvt9000_64" do
  mode 00777
  action :create
end

directory "/home/ec2-user/bvt9000_64/installs" do
  mode 00777
  action :create
end

cookbook_file "/home/ec2-user/bvt9000_64/installs/wsdtxcs_9000_linux_64.tar" do
  source "wsdtxcs_9000_linux_64.tar"
  action :create
end

cookbook_file "/home/ec2-user/temp/install.sh" do
  source "install.sh"
  action :create
end

#ENV['VRMFNUM'] = "9000"
#ENV['BITTYPE'] = "64"
#ENV['BVTDIR'] = "/home/ec2-user/bvt9000_64"
#ENV['TXINSTALLS_CORE'] = "wsdtxcs"
#ENV['TXINSTALLS_DK'] = "none"
#ENV['TXINSTALLS_INTERIMFIX'] = "none"
#ENV['TXINSTALLS_NOENABLEGPFS'] = "1"

my_env_vars = {"VRMFNUM" => "9000", "BITTYPE" => "64", "BVTDIR" => "/home/ec2-user/bvt9000_64", "TXINSTALLS_CORE" => "wsdtxcs", "TXINSTALLS_DK" => "none", "TXINSTALLS_INTERIMFIX" => "none", "TXINSTALLS_NOENABLEGPFS" => "1"}

script "run_install" do
  interpreter "bash"
  user "ec2-user"
  code <<-EOH
  cd home/ec2-user/temp
  ksh ./install.sh
  EOH
  environment my_env_vars
end

ruby_block "add_startup_script_to_bash_profile" do
  block do
    file = Chef::Util::FileEdit.new("/home/ec2-user/.bash_profile")
    file.insert_line_after_match(
	  "# User specific environment and startup programs",
      "\n. ~/bvt9000_64/wtx_9000/setup"
    )
    file.write_file
  end
end

#TODO: remove unneeded files? tar file? other things? clean up

results = "/tmp/output.txt"
file results do
    action :delete
end

bash "run_example_map" do
    code <<-EOH
	. /home/ec2-user/bvt9000_64/wtx_9000/setup
    cd ${DTX_HOME_DIR}/examples/general/map/sinkmap
    dtxcmdsv sinkmap.mmc &> #{results}
    EOH
end

ruby_block "print_results" do
    only_if { ::File.exists?(results) }
    block do
        print "\n"
        File.open(results).each do |line|
            print line
        end
    end
end

