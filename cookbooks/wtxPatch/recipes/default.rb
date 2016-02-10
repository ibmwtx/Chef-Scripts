#
# Cookbook Name:: wtxPatch
# Recipe:: default
#
# Copyright 2014, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

cookbook_file "/home/ec2-user/bvt9000_64/wtx_9000/bin/Patch.txt" do
  source "Patch.txt"
  action :create
end

cookbook_file "/home/ec2-user/bvt9000_64/wtx_9000/bin/resourceregistry.sh" do
  source "resourceregistry.sh"
  action :create
end