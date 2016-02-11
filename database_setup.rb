require "data_mapper"

env = nil

if ENV["bakak_env"]
  env = ENV["bakak_env"]
else
  env = "local"
end

case env
  when "local"
    DataMapper::Logger.new($stdout, :debug)
    DataMapper.setup(:default, 'sqlite://./project.db')
  when "ci"
    DataMapper::Logger.new($stdout, :debug)
    DataMapper.setup(:default, 'postgres://ubuntu:@127.0.0.1:5432/circle_test')
end