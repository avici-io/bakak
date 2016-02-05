require 'mailgun'
require_relative 'config'
require 'contracts'

class Emailer
  @mg_client = Mailgun::Client.new 'key-88367605e3fc4e98aeab39186b0aeb50'
  class << self
    include Contracts::Core
    include Contracts::Builtin

    Contract String, String, String => Any
    def mail mail_address, subject, contents
      message_params = {
          from: 'admin@avici.io',
          to: mail_address,
          subject: subject,
          contents: contents
      }
      @mg_client.send_message "avici.io", message_params
    end

    Contract String, String, String => Any
    def mail_reset_password mail_address, username, token
      subject = "Avici.io [#{Time.now.to_i}]: Password Reset for #{username}"
      body = "You have requested a password reset for your avici.io account. Token is #{token}."
      mail mail_address, subject, body
    end
  end
end