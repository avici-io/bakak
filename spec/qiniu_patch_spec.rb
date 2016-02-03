require 'qiniu'
require_relative '../qiniu_patch'
require 'rspec'
require_relative '../config'

Qiniu.establish_connection! access_key: CONFIG[:qiniu][:ak], secret_key: CONFIG[:qiniu][:sk]

describe Qiniu do
  it "should be able to list files" do
    r = Qiniu.list_prefix('avicidev', "", nil, 200)
    expect(r[0]).to be(200)
  end
end