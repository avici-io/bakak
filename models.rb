require "data_mapper"
require "bcrypt"
require "json"
require 'dm-migrations'
require "openssl"

require "base64"
require_relative "encrypt"



module NilableGet
  def nget(n)
    return n if n.nil?
    if n.is_a? String
      n = n.to_i
    end
    return nil if n == 0
    return self.get(n)
  end
end

class User
  extend NilableGet
  include DataMapper::Resource

  has n, :games

  property :created_at, DateTime
  property :id, Serial

  property :username, String, :length => 2..40, :required => true, :unique => true, :format => /[A-Za-z0-9_\-]*/
  property :password, BCryptHash
  property :email, String, :required => true, :unique => true, :format => :email_address
  property :description, Text, :length => 0..400

  def public_object
    {
      id: self.id,
      username: self.username,
      email: self.email,
      description: self.description,
      games: self.games.map{|it| it.public_object}
    }
  end

  def generate_apikey(duration)
    terminal_time = Time.now.to_i + duration
    obj = {id: id, expires: terminal_time}
    Encryption.encrypt_hash(obj)
  end
end

def User.from_apikey(key)
  if key.nil?
    $log.debug "Nil Key"
    return nil
  end
  begin
    h = Encryption.decrypt_hash(key)
    expire_time = Time.at(h[:expires])
    if Time.now > expire_time
      $log.debug "Expired"
      return nil
    else
      return User.get(h[:id])
    end
  rescue Exception => exc
    $log.debug "When Deciphering ApiKey, got #{exc.backtrace}"
    return nil
  end
end

class Game
  extend NilableGet
  include DataMapper::Resource

  belongs_to :user
  has n, :comments

  property :created_at, DateTime
  property :id, Serial

  property :title, String, :length => 2..60
  property :tagline, String, :length => 2..100, :required => true
  property :description, Text, :length => 0..400, :default => lambda {|r,p| ""}
  property :category, Integer, :required => true
  property :public, Boolean, :default => lambda {|r, p| false}

  property :checksums, Text, :default => lambda {|r, p| "{}"}

  property :html, Text, :default => lambda {|r, p| ""}

  def get_file_uptoken
    generate_token
  end

  def rating
    rats = self.comments.map{|it| it.rating}.compact
    if rats.length == 0
      return 0
    else
      return rats.inject(:+).to_f / rats.length
    end
  end

  def generate_token(path = nil)
    if path
      Qiniu::Auth.generate_uptoken(Qiniu::Auth::PutPolicy.new("avicidev", path))
    else
      Qiniu::Auth.generate_uptoken(Qiniu::Auth::PutPolicy.new("avicidev"))
    end
  end

  def public_object
    {
      id: self.id,
      title: self.title,
      tagline: self.tagline,
      description: self.description,
      author: {
        id: self.user.id,
        username: self.user.username,
        email: self.user.email
      },
      category: self.category,
      comments: self.comments.map{|it| it.public_object},
      checksums: JSON.parse(self.checksums),
      html: self.html,
      rating: self.rating,
      tokens: {
          resources: generate_token,
          small: generate_token("#{self.id}/small"),
          large: generate_token("#{self.id}/large"),
          marquee: generate_token("#{self.id}/marquee")
      }
    }
  end

  # helper method for testing
  def set_checksums_by_ruby_hash(ruby_hash)
    self.update checksums: JSON.dump(ruby_hash)
  end
end

class Comment
  extend NilableGet
  include DataMapper::Resource

  belongs_to :game
  belongs_to :user

  property :created_at, DateTime
  property :id, Serial

  property :rating, Integer
  property :contents, Text, :length => 0..400, :required => true

  def public_object
    {
      id: self.id,
      rating: self.rating,
      contents: self.contents,
      author: {
        id: self.user.id,
        username: self.user.username,
        email: self.user.email
      }
    }
  end
end

DataMapper.auto_migrate!
DataMapper.finalize
