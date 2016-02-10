#
# Cookbook Name:: wtxUninstall
# Recipe:: default
#
# Copyright 2014, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

bash "run_uninstall_command" do
	user "ec2-user"
    code <<-EOH
	cd home/ec2-user/bvt9000_64
	rm -rf wtx_9000
    EOH
end

ruby_block "delete_startup_script_from_bash_profile" do
  block do
    file = Chef::Util::FileEdit.new("/home/ec2-user/.bash_profile")
    file.search_file_delete_line(
      ". ~/bvt9000_64/wtx_9000/setup"
    )
    file.write_file
  end
end

