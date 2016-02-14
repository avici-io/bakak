require "mailgun"

mg_client = Mailgun::Client.new "key-88367605e3fc4e98aeab39186b0aeb50"

message_params = {:from => "noreply.account@avici.io",
                  :to => "liubaqiao@gmail.com",
                  :subject => "Your Account is Lost",
                  :text => "This is for testing"
                 }

mg_client.send_message "avici.io", message_params