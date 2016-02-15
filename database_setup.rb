require "data_mapper"

if ENV["CI"]
  puts "Loading From CI"
  DataMapper::Logger.new($stdout, :debug)
  DataMapper.setup(:default, 'postgres://ubuntu@localhost/circle_test')
elsif ENV["DEPLOY"]
  DataMapper.setup(:default, ENV['DATABASE_URL'] || 'postgres://localhost/mydb')
else
  puts "Loading from Local"
  DataMapper::Logger.new($stdout, :error)
  DataMapper.setup(:default, 'sqlite://./project.db')
end