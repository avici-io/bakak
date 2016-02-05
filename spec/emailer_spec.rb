require 'rspec'
require 'rantly'
require 'gmail'
require 'rantly/rspec_extensions'    # for RSpec
require_relative '../mailer'

RSpec.describe Emailer do
  it "should be able to deliver emails" do
    target = "liubaqiao@gmail.com"
    Emailer.mail_reset_password target, "BakaBBQ", "233333"
    expect(true).to be(true)
  end
end