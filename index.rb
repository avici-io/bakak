require_relative "config"

require "logger"
require "sinatra"
require "sinatra/reloader" if development?
require "sinatra/json"
require "data_mapper"

require "pry"

DataMapper::Logger.new($stdout, :debug)
DataMapper.setup(:default, 'sqlite:///project.db')

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
      json :key => u.generate_apikey(3600)
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

  post = User.new(
    :username => username,
    :password => password,
    :email => email
  )

  if post.save
    status 201
    json :id => post.id
  else
    post.errors.each do |e|
      $log.debug e
    end
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
  if maybe_user
    user = maybe_user
    if current_user
      if current_user.id == user.id
        info = {
            email: params[:email]
        }
        if user.update(info.select{|k, v| !v.nil?})
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

post '/auth/me' do
  if !params[:key].nil?
    $log.debug params[:key]
    maybe_user = User.from_apikey(params[:key])
    $log.debug "Maybe User"
    $log.debug maybe_user
    if maybe_user
      status 200
      json :id => maybe_user.id
    else
      status 404
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
        game = u.games.new(title: title, tagline: tagline, description: description, category: category)
        if game.save
          status 201
          json :id => game.id, :title => game.title
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
  id = params[:id]
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
            tagline: params[:tagline],
            description: params[:description],
            category: params[:category]
        }

        if game.update(info.select{|k, v| !v.nil?})
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
    if game_id && contents && Game.get(game_id)
      game = Game.get(game_id)
      c = game.comments.new(rating: rating, contents: contents)
      c.user = user
      if c.save
        status 201
        json c.public_object
      else
        status 400
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
