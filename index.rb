require_relative "config"

require "logger"
require "sinatra"
require "sinatra/reloader" if development?
require "sinatra/json"
require "data_mapper"
require_relative "qiniu_patch"
require_relative 'mailer'

require 'sinatra/cross_origin'


options "*" do
  response.headers["Allow"] = "HEAD,GET,PUT,POST,DELETE,OPTIONS"
  response.headers["Access-Control-Allow-Methods"] = "POST, GET, OPTIONS, DELETE, PATCH, PUT"
  response.headers["Access-Control-Allow-Headers"] = "X-Requested-With, X-HTTP-Method-Override, Content-Type, Cache-Control, Accept"
  200
end

configure do
  enable :cross_origin
end

Qiniu.establish_connection! access_key: CONFIG[:qiniu][:ak], secret_key: CONFIG[:qiniu][:sk]

require_relative "path_resolver"
require_relative "qiniu_patch"

require "pry"


require_relative "models"

$log = Logger.new(STDOUT)

get "/" do
  status 200
end

post '/auth' do
  username = params[:username]
  password = params[:password]
  u = User.first(:username => username)
  if u
    if u.password == password
      status 200
      json u.public_object.merge({:key => u.generate_apikey(3600)})
    else
      status 403
    end
  else
    status 404
  end
end


post '/user' do

end

# Create a New User
post '/user/new' do
  $log.debug params
  username = params[:username]
  password = params[:password]
  email = params[:email]

  user = User.new(
      :username => username,
      :password => password,
      :email => email
  )

  if user.save
    status 201
    user.games.create :title => "Untitled Game", :tagline => "Tagtagtag", :description => "Hihihi", :category => 0
    json :id => user.id
  else
    status 400
  end
end

# Get User Info
get '/user/:id' do
  r = params['id'].to_i
  if r
    u = User.get(r)
    if u
      status 200
      json u.public_object
    else
      status 404
    end
  else
    status 400
  end
end

# Modify User
patch '/user/:id' do

  maybe_user = User.nget(params[:id])
  current_user = User.from_apikey(params[:key])
  p current_user.nil?
  if maybe_user
    user = maybe_user
    if current_user
      if current_user.id == user.id
        info = {
            email: params[:email],
            description: params[:description]
        }
        if user.update(info.select { |k, v| !v.nil? })
          status 200
        else
          status 400
        end
      else
        status 403
      end
    else
      status 403
    end
  else
    status 404
  end
end

post '/user/:id/reset' do
  maybe_user = User.nget(params[:id])
  email = params[:email]
  if maybe_user
    user = maybe_user
    if user.email == email
      reset_token = user.generate_password_reset_token
      Emailer.mail_reset_password user.email, user.username, reset_token
      status 200
    else
      status 403
    end
  else
    status 404
  end
end

post '/auth/me' do
  if !params[:key].nil?
    $log.debug params[:key]
    maybe_user = User.from_apikey(params[:key])
    $log.debug "Maybe User"
    $log.debug maybe_user
    if maybe_user
      status 200
      json maybe_user.public_object.merge({:key => maybe_user.generate_apikey(3600)})
    else
      status 403
    end
  else
    status 400
  end
end

post '/game/new' do
  key = params[:key]
  if !key
    status 401
  else
    maybe_user = User.from_apikey(params[:key])
    if maybe_user
      u = maybe_user
      $log.debug u
      if !u
        status 401
      else
        title = params[:title]
        tagline = params[:tagline]
        description = params[:description]
        category = params[:category]
        public = params[:category] == "true" ? true : false
        game = u.games.new(title: title, tagline: tagline, description: description, category: category, public: public)
        if game.save
          status 201
          json game.public_object
        else
          game.errors.each do |e|
            puts e
          end
          status 400
        end
      end
    else
      status 403
    end
  end
end

# Get Game Info
get '/game/:id' do
  id = params[:id].to_i
  if id == 0
    status 401
  else
    status 200
    g = Game.get(id)
    if g
      json g.public_object
    else
      status 404
    end
  end
end

get '/game/:id/html' do
  maybe_game = Game.get(params[:id].to_i)
  if maybe_game
    game = maybe_game
    response.headers["Content-Type"] = "text/html; charset=utf-8"
    response.headers["X-Frame-Options"] = "true"
    body = nil
    if game.html && game.html != ""
      body = "<p>No Game Yet</p>"
    else
      body = game.html
    end
    response.write body
  else
    status 404
  end
end

# Modify Game Info
patch '/game/:id' do
  maybe_user = User.from_apikey(params[:key])
  if maybe_user
    user = maybe_user
    maybe_game = Game.nget(params[:id])
    if maybe_game
      game = maybe_game
      if game.user == user
        info = {
            title: params[:title],
            tagline: params[:tagline],
            description: params[:description],
            category: params[:category],
            checksums: params[:checksums],
            html: params[:html],
            public: params[:public] == nil ? nil : (params[:public] == "true" ? true : false)
        }
        if game.update(info.select { |k, v| !v.nil? })
          status 200
          json game.public_object
        else
          status 400
        end
      else
        status 403
      end
    else
      status 404
    end
  else
    status 403
  end
end

# Delete Game
delete '/game/:id' do
  maybe_user = User.from_apikey(params[:key])
  if maybe_user
    user = maybe_user
    maybe_game = Game.nget(params[:id])
    if maybe_game
      game = maybe_game
      if game.user == user
        game.destroy
        status 200
      else
        status 403
      end
    else
      status 404
    end
  else
    status 403
  end
end

post '/comment' do

end

post '/comment/new' do
  game_id = params[:game]
  rating = params[:rating]
  contents = params[:contents]
  maybe_user = User.from_apikey(params[:key])
  if maybe_user
    user = maybe_user
    if game_id && contents && Game.get(game_id) && (rating.nil? || (rating.to_i > 0 && rating.to_i <= 5))
      rating = rating.to_i
      game = Game.get(game_id)
      if game.comments.select { |it| it.rating }.map { |it| it.user.id }.include?(user.id) || game.user.id == user.id
        status 409
      else
        c = game.comments.new(rating: rating, contents: contents)
        c.user = user
        if c.save
          status 201
          json c.public_object
        else
          status 400
        end
      end
    else
      status 400
    end
  else
    status 403
  end
end

# Get Comment Info
get '/comment/:id' do
  maybe_id = params[:id]
  if maybe_id.to_i == 0
    status 400
  else
    id = maybe_id.to_i
    maybe_c = Comment.get(id)
    if maybe_c
      c = maybe_c
      status 200
      json c.public_object
    else
      status 404
    end
  end
end

# Delete Comment
delete '/comment/:id' do
  maybe_user = User.from_apikey(params[:key])
  if maybe_user
    user = maybe_user
    maybe_comment = Comment.nget(params[:id])
    if maybe_comment
      comment = maybe_comment
      if comment.user == user
        comment.destroy
        status 200
      else
        status 403
      end
    else
      status 404
    end
  else
    status 403
  end
end

post '/screenshot' do

end

post '/screenshot/new' do
  key = params[:key]
  game_id = params[:game]
  if key and game_id.to_i != 0
    maybe_game = Game.nget game_id
    maybe_user = User.from_apikey(key)
    if maybe_game.nil?
      status 404
    elsif maybe_user.nil? or maybe_game.user.id != maybe_user.id
      $log.debug [maybe_user.nil?, maybe_game.user.id != maybe_user]
      status 403
    else
      status 201
      game = maybe_game
      user = maybe_user
      s = game.screenshots.new
      s.save
      $log.debug game.public_object
      json s.public_object
    end
  else
    status 400
  end
end

delete '/screenshot/:id' do
  key = params[:key]
  game_id = params[:game]
  if key and game_id.to_i != 0
    maybe_game = Game.nget game_id
    maybe_user = User.from_apikey(key)
    maybe_screenshot = Screenshot.nget(params[:id])
    if maybe_game.nil? or maybe_screenshot.nil?
      status 404
    elsif maybe_user.nil? or maybe_game.user.id != maybe_user.id or maybe_screenshot.game.id != maybe_game.id
      status 403
    else
      screenshot = maybe_screenshot
      screenshot.destroy
      status 200
    end
  else
    status 400
  end
end

$path_resolver = PathResolver.new
get '/files/:game_id/*.*' do
  maybe_game_id = params[:game_id]
  if maybe_game_id.to_i > 0
    game_id = maybe_game_id.to_i
    url = params['splat'].join(".")
    base_path = CONFIG[:qiniu][:basepath]
    r = $path_resolver.resolve(game_id, url)
    if r
      redirect base_path + r
    else
      status 404
    end
  else
    status 404
  end
end

get '/qiniu/ls' do
  r = Qiniu.list_prefix 'avicidev', '', nil, 999
  if r[0] == 200
    status 200
    json r[1]["items"].map { |it| it["key"] }
  else
    status 500
    json r[1]
  end
end


