require_relative "../index"

require "rack/test"
require "rspec"
require "json"

describe "The Avici.io Backend" do
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  it "says hello" do
    get "/"
    expect(last_response).to be_ok
  end

  it "can be registered with a lot of valid users" do
    property_of {
      [string(:alnum), string, string(:alnum), string(:alnum), string(:alnum)]
    }.check {|a|
      post "/user/new", "username" => a[0], "password" => a[1], "email" => "#{a[2]}@#{a[3]}.#{a[4]}"
      expect(last_response.status).to be(201)

      post "/auth", "username" => a[0], "password" => a[1]
      expect(last_response.status).to be(200)

      data = JSON.parse last_response.body
      k = data["key"]
      expect(k).not_to be(nil)

      post "/auth/me", "key" => k
      expect(last_response.status).to be(200)
      id = JSON.parse(last_response.body)["id"]
      expect(id.to_i).not_to eq(0)

      get "/user/#{id}"
      expect(JSON.parse(last_response.body)["username"]).to eq(a[0])
    }
  end

  it "registered users should exist" do
    property_of {
      range(1, 100)
    }.check {|i|
      get "/user/#{i}"
      expect(last_response.status).to be(200)
    }
  end
end