#Creating HTTPD service named 'Customers'
httpd_service 'customers' do
	mpm 'prefork'
	action [:create, :start]
end

# Creating config file for 'Customers'
httpd_config 'customers' do
	instance 'customers'
	source 'customers.conf.erb'
	notifies :restart, 'httpd_service[customers]'
end	

#Creating document root directory
directory node['awesome_customers']['document_root'] do
	recursive true
end

# Load the secrets file and the encrypted data bag item that holds the database password.
password_secret = Chef::EncryptedDataBagItem.load_secret(node['awesome_customers']['passwords']['secret_path'])
user_password_data_bag_item = Chef::EncryptedDataBagItem.load('passwords', 'db_admin_password', password_secret)


#Writing the home page
template "#{node['awesome_customers']['document_root']}/index.php" do
	source 'index.php.erb'
	mode '0755'
	owner node['awesome_customers']['user']
	group node['awesome_customers']['group']
	variables({
		:database_password => user_password_data_bag_item['password']
	})
end

#Install mod_php5 Apache Module:
httpd_module 'php' do
	instance 'customers'
end

#Install php5-mysql module
package 'php-mysql' do
	action:install
	notifies :restart, 'httpd_service[customers]'
end

# Load the secrets file and the encrypted data bag item that holds the database password.
#password_secret = Chef::EncryptedDataBagItem.load_secret(node['awesome_customers']['passwords']['secret_path'])
#user_password_data_bag_item = Chef::EncryptedDataBagItem.load('passwords', 'db_admin_password', password_secret)
