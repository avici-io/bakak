require_relative "../index"

require "rack/test"
require "rspec"
require "json"

require 'rantly'
require 'rantly/rspec_extensions'    # for RSpec

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
      [
          string(:alnum), string(:alnum), string(:alnum), string(:alnum), string(:alnum),
          {title: string(:alnum), tagline: string(:alnum), description: string(:alnum), category: range(1,8)},
          dict{
            [
                (string(:alnum) + "/") * range(0, 3) + string(:alnum) + "." + choose("jpg", "png", "json"),
                string(:alnum) + "." + choose("jpg", "png", "json")
            ]
          }
      ]
    }.check(10) {|a|
      game_params = a[5]
      checksum_data = a[6]
      post "/user/new", "username" => a[0], "password" => a[1], "email" => "#{a[2]}@#{a[3]}.#{a[4]}"
      expect(last_response.status).to be(201)

      post '/user/new', 'username' => a[1], 'password' => a[0], 'email' => "#{a[3]}@#{a[4]}.com"
      expect(last_response.status).to be(201)

      post "/auth", "username" => a[0], "password" => a[1]
      expect(last_response.status).to be(200)

      data = JSON.parse last_response.body
      k = data["key"]
      expect(k).not_to be(nil)

      post "/auth", "username" => a[1], "password" => a[0]
      expect(last_response.status).to be(200)

      data = JSON.parse last_response.body
      k2 = data["key"]
      expect(k2).not_to be(nil)

      post "/auth/me", "key" => k
      expect(last_response.status).to be(200)
      id = JSON.parse(last_response.body)["id"]
      expect(id.to_i).not_to eq(0)

      get "/user/#{id}"
      expect(JSON.parse(last_response.body)["username"]).to eq(a[0])


      game_params[:key] = k
      post "/game/new", game_params
      expect(last_response.status).to be(201)
      game_id = JSON.parse(last_response.body)["id"]

      post "/comment/new", "game" => game_id, "contents" => a[2], "key" => k2, "rating" => 3
      expect(last_response.status).to be(201)
      comment_id = JSON.parse(last_response.body)["id"]

      get "/comment/#{comment_id}"
      expect(last_response.status).to be(200)
      expect(JSON.parse(last_response.body)["contents"]).to eq(a[2])

      patch "/user/#{id}", "key" => k
      expect(last_response.status).to be(200)

      patch "/user/#{id}", "key" => k, "email" => "#{a[2]}@#{a[4]}.#{a[3]}"
      expect(last_response.status).to be(200)

      get "/user/#{id}"
      puts last_response.errors
      expect(last_response.status).to be(200)
      expect(JSON.parse(last_response.body)["email"]).to eq("#{a[2]}@#{a[4]}.#{a[3]}")

      patch "/game/#{game_id}"
      expect(last_response.status).to be(403)

      patch "/game/#{game_id}", "key" => k
      expect(last_response.status).to be(200)

      patch "/game/#{game_id}", "key" => k, "tagline" => a[0]
      expect(last_response.status).to be(200)

      patch "/game/#{game_id}", "key" => k, "checksums" => checksum_data.to_json, "html" => "<p>hi</p>"
      expect(last_response.status).to be(200)

      post "/comment/new", "game" => game_id, "contents" => a[2], "key" => k, "rating" => 3
      expect(last_response.status).to be(409)

      get "/game/#{game_id}"
      expect(JSON.parse(last_response.body)["tagline"]).to eq(a[0])
      expect(JSON.parse(last_response.body)["checksums"]).to eq(checksum_data)

      g = JSON.parse(last_response.body)
      expect(g["tokens"]).not_to eq(nil)
      expect(g["tokens"]["small"].length).to be > 1
      expect(g["tokens"]["large"].length).to be > 1
      expect(g["tokens"]["marquee"].length).to be > 1
      expect(g["html"].length).to be > 1
      expect(g["rating"]).to eq(3)

      checksum_data.each do |k, v|
        get "/files/#{game_id}/#{k}"
        follow_redirect!
        expect(last_request.url).to eq(CONFIG[:qiniu][:basepath] + v)
      end
    }
  end

  it "should be able to list files" do
    get '/qiniu/ls'
    expect(last_response.status).to be(200)
    obj = JSON.parse(last_response.body)
    expect(obj).to be_an_instance_of(Array)
    expect(obj[0]).to be_an_instance_of(String)
  end
end