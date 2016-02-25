require_relative "config"

require "contracts"
require "redis"
require "json"

class PathResolver
  include Contracts::Core
  include Contracts::Builtin

  def initialize
    @redis = Redis.new(CONFIG[:redis])
    if CONFIG[:redis][:password]
      @redis.auth CONFIG[:redis][:password]
    end
    @redis.keys("*").each do |k|
      @redis.set(k, nil)
      @redis.expire(k, 60 * 10)
    end
  end

  # url must match js/index.js, with no beginning slash
  Contract Num, String => Maybe[String]
  def resolve game_id, url
    if Game.get(game_id)
      unless cached?(game_id)
        cache game_id
        resolve game_id, url
      else
        t = Time.now
        get_from_redis game_id, url
      end
    else
      nil
    end
  end

  Contract Num => Bool
  def cached? game_id
    r = @redis.get("game_#{game_id}")
    !(r.nil? || r.empty?)
  end

  def cache game_id
    maybe_game = Game.get(game_id)
    checksum_obj = JSON.parse(maybe_game.checksums)
    @redis.set("game_#{game_id}", "true")
    checksum_obj.each do |k, v|
      @redis.set("game_#{game_id}_#{k}", v)
    end
  end

  def uncache game_id
    @redis.del "game_#{game_id}"
  end

  Contract Num, String => Maybe[String]
  def get_from_redis game_id, url
    @redis.get("game_#{game_id}_#{url}")
  end
end