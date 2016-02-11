require "data_mapper"

if ENV["CI"]
  puts "Loading From CI"
  DataMapper::Logger.new($stdout, :debug)
  DataMapper.setup(:default, 'sqlite::memory:')
else
  puts "Loading from Local"
  DataMapper::Logger.new($stdout, :debug)
  DataMapper.setup(:default, 'sqlite://./project.db')
end