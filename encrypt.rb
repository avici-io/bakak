require "openssl"
require "base64"
require "json"

class Encryption
  @cipher = OpenSSL::Cipher.new('AES-128-CBC')
  @cipher.encrypt
  @key = @cipher.random_key
  @iv = @cipher.random_iv
  @decipher = OpenSSL::Cipher::AES.new(128, :CBC)
  @decipher.decrypt
  @decipher.key = @key
  @decipher.iv = @iv

  class << self
    def encrypt(str)
      @cipher.reset
      r = @cipher.update(str) + @cipher.final
      Base64.encode64(r)
    end

    def decrypt(str)
      str = Base64.decode64(str)
      @decipher.reset
      @decipher.update(str) + @decipher.final
    end

    def encrypt_hash(hash)
      obj = JSON.dump(hash)
      b64 = Base64.encode64(obj)
      encrypt(b64)
    end

    def decrypt_hash(str)
      Hash[JSON.load(Base64.decode64(decrypt(str))).map{|(k,v)| [k.to_sym,v]}]
    end
  end
end
