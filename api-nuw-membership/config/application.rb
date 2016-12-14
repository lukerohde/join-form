require 'dotenv'
Dotenv.load

load "./config/environment/#{ENV['RACK_ENV']||'development'}.rb"

Dir["./helpers/*.rb"].each {|file| p file; load file; }
Dir["./config/initializers/*.rb"].each {|file| p file; load file}
Dir["./models/*.rb"].each {|file| p file; load file}
Dir["./join-consumer/*.rb"].each {|file| p file; load file}

