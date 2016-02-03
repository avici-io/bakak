require 'rspec'
require 'rantly'
require 'rantly/rspec_extensions'    # for RSpec
require "data_mapper"

DataMapper.setup(:default, 'sqlite:///project.db')
require_relative "../path_resolver"
require_relative "../models"

RSpec.describe PathResolver do
  it "should be able to resolve urls correctly" do
    property_of {
      {
          user: User.new(username: string, password: string, email: string(:alnum) + "@" + string(:alnum) + ".com"),
          game_data: {
              title: string,
              tagline: string,
              description: string,
              category: range(1,8)
          },
          game_checksums: dict{[string(:alnum) + "/" + string(:alnum), string(:alnum)]}
      }
    }.check{ |h|
      user = h[:user]
      game_data = h[:game_data]
      game_checksums = h[:game_checksums]

      expect(user.save).to eq(true)
      game = user.games.new(game_data)
      expect(game.save).to eq(true)
      expect(game.set_checksums_by_ruby_hash(h[:game_checksums])).to eq(true)
      id = game.id
      expect(id).to be > 0

      path_resolver = PathResolver.new

      game_checksums.each do |k, v|
        r = path_resolver.resolve id, k
        expect(r).to eq(v)
      end
    }
  end
end