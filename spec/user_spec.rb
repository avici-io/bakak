require "rspec"
require "json"
require "data_mapper"
require_relative "../config"
require "logger"

require 'rantly'
require 'rantly/rspec_extensions'    # for RSpec

require_relative "../models"
require_relative "../qiniu_patch"

require_relative "../encrypt"
Qiniu.establish_connection! access_key: CONFIG[:qiniu][:ak], secret_key: CONFIG[:qiniu][:sk]

$log = Logger.new(STDOUT)



describe "The User Model" do
  it "users shall be able to generate keys" do
    property_of{
      [string(:alnum), string(:alnum), string(:alnum), range(1000,8000)]
    }.check(20) {|a|
      g_username = a[0]
      g_password = a[1]
      g_email = "lalala@meow#{a[2]}.com"
      g_duration = a[3]
      u = User.new(username: g_username, password: g_password, email: g_email)
      expect(u.save).to eq(true)

      expect(u.id).to be_a(Fixnum)

      generated_key = u.generate_apikey(g_duration)
      expect(u.id).to eq(User.from_apikey(generated_key).id)
      expect(u.id).to eq(User.from_resetkey(u.generate_resetkey).id)
    }
  end
end