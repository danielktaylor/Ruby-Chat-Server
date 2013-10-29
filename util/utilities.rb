require 'mail'

class Utilities
  class << self
    def send_reset_email(email, password)
      message = "You requested a password reset. Your new password is: #{password}"
      message_id = Mail.deliver do
        from    'no-reply@simplechat.com' #TODO change
        to      email
        subject 'Simple Chat Password Reset'
        body    message
      end

      return true
    end

    def send_message(from, to, message, timestamp)
      unless $messages[to]
        $messages[to] = []
      end

      $messages[to].push([from, message, timestamp])
      return true
    end
  end
end
