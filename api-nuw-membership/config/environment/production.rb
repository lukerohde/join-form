require 'active_record'
require 'ignorable'

ActiveRecord::Base.establish_connection(
  :adapter  => "sqlserver",
  :host     => ENV['db_host'],
  :username => ENV['db_username'],
  :password => ENV['db_password'],
  :database => ENV['db_database']
)
