require 'rspec'
require 'rantly'
require 'rantly/rspec_extensions'    # for RSpec

require_relative "../encrypt"

RSpec.describe Encryption do
  it "after encryption and decryption it should be the original value" do
    property_of {
      string
    }.check{ |s|
      expect(s).to eq(Encryption.decrypt(Encryption.encrypt(s)))
    }
  end

  it "encrypts ruby hash correctly" do
    property_of {
      dict{ [string, integer] }
    }.check{ |h|
      expect(Hash[h.map{|k, v| [k.to_sym,v]}]).to eq(Encryption.decrypt_hash(Encryption.encrypt_hash(h)))
    }
  end

  it "for the same encryption it should always be the same" do
    property_of {
      string
    }.check{ |s|
      expect(Encryption.encrypt(s)).to eq(Encryption.encrypt(s))
    }
  end
end
