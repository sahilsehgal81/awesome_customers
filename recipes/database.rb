#
# Cookbook Name:: awesome_customers
# Recipe:: database
#
# Copyright (c) 2015 The Authors, All Rights Reserved.
#Configure MySQL2 Ruby Gem
mysql2_chef_gem 'default' do
	action :install
end

#Configure MySQL Client
mysql_client 'default' do
	action :create
end

#Load the Secret File and encrypted data bag item that hosls the root password.
password_secret = Chef::EncryptedDataBagItem.load_secret(node['awesome_customers']['passwords']['secret_path'])
root_password_data_bag_item = Chef::EncryptedDataBagItem.load('passwords', 'sql_server_root_password', password_secret)

#Configure MySQL Service.
mysql_service 'default' do
	initial_root_password root_password_data_bag_item['password']
	action [:create, :start]
end

#Create Database Instance
mysql_database node['awesome_customers']['database']['dbname'] do
	connection(
		:host => node['awesome_customers']['database']['host'],
		:username => node['awesome_customers']['database']['username'],
 		:password => root_password_data_bag_item['password']
	)
	action :create
end

#Load Encrypted Data Bag that holds password of DB User
user_password_data_bag_item = Chef::EncryptedDataBagItem.load('passwords', 'db_admin_password', password_secret)
	
# Create MySQL Database User:
mysql_database_user node['awesome_customers']['database']['app']['username'] do
	connection(
		:host => node['awesome_customers']['database']['host'],
		:username => node['awesome_customers']['database']['username'],
		:password => root_password_data_bag_item['password']
	)
	password user_password_data_bag_item['password']
	database_name node['awesome_customers']['database']['dbname']
	host node['awesome_customers']['database']['host']
	action [:create, :grant]
end

#Creating Scema File
cookbook_file node['awesome_customers']['database']['seed_file']  do
	source 'create-tables.sql'
	mode '0600'
	user 'root'
	group 'root'
end

# Seed database with a table and test data
execute 'initialize database' do
	command "mysql -h #{node['awesome_customers']['database']['host']} -u #{node['awesome_customers']['database']['app']['username']} -p#{user_password_data_bag_item['password']} -D #{node['awesome_customers']['database']['dbname']} < #{node['awesome_customers']['database']['seed_file']}"
	not_if  "mysql -h #{node['awesome_customers']['database']['host']} -u #{node['awesome_customers']['database']['app']['username']} -p#{user_password_data_bag_item['password']} -D #{node['awesome_customers']['database']['dbname']} -e 'describe customers;'"
end 
