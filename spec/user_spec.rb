require "rspec"
require "json"
require_relative "../models"

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
      u.save!

      expect(u.id).to eq(User.from_apikey(u.generate_apikey(g_duration)).id)
    }
  end
end