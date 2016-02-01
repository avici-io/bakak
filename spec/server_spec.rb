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
      [
          string(:alnum), string, string(:alnum), string(:alnum), string(:alnum),
          {title: string(:alnum), tagline: string(:alnum), description: string(:alnum), category: range(1,8)}
      ]
    }.check(30) {|a|
      game_params = a[5]
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


      game_params[:key] = k
      post "/game/new", game_params
      expect(last_response.status).to be(201)
      game_id = JSON.parse(last_response.body)["id"]

      post "/comment/new", "game" => game_id, "contents" => a[2], "key" => k
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
      expect(last_response.status).to be(200)
      expect(JSON.parse(last_response.body)["email"]).to eq("#{a[2]}@#{a[4]}.#{a[3]}")

      patch "/game/#{game_id}"
      expect(last_response.status).to be(403)

      patch "/game/#{game_id}", "key" => k
      expect(last_response.status).to be(200)

      patch "/game/#{game_id}", "key" => k, "tagline" => a[0]
      expect(last_response.status).to be(200)

      get "/game/#{game_id}"
      expect(JSON.parse(last_response.body)["tagline"]).to eq(a[0])
    }
  end

  it "registered users should exist" do
    property_of {
      range(1, 30)
    }.check {|i|
      get "/user/#{i}"
      # puts last_response.errors
      expect(last_response.status).to be(200)
      obj = JSON.parse(last_response.body)
      $log.debug "PPPPPPP"
      $log.debug obj
      expect(obj["games"]).to be_an_instance_of(Array)
      expect(obj["games"].length).to be >= 1
      expect(obj["games"].first["id"]).to be > 0
      expect(obj["games"].first["comments"]).to be_an_instance_of(Array)
      expect(obj["games"].first["comments"].first["id"]).not_to eq(nil)
      expect(obj["games"].first["comments"].first["contents"]).not_to eq(nil)
      expect(obj["games"].first["comments"].first["author"]["id"]).not_to eq(nil)
    }
  end
end