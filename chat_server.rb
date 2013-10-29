# System libraries
require 'json'

# Custom libraries
require './util/utilities'
require './util/db'

class ChatServer < Sinatra::Application
  # temporary message store (switch to iOS notification service)
  #   key: email
  #   value: list of messages [sender, message, timestamp]
  $messages = {}

  helpers do
    def protected!
      if email = authorized?
        return email
      end
      headers['WWW-Authenticate'] = 'Basic realm="Restricted Area"'
      halt 401, "Not authorized\n"
    end

    def authorized?
      @auth ||= Rack::Auth::Basic::Request.new(request.env)
      if @auth.provided? and @auth.basic? and @auth.credentials
        email, password = @auth.credentials
        if Db.verify_password(email, password)
          return email
        end
      end
      return nil
    end
  end

  # Register a new user
  post '/register' do
    email = params['email']
    password = params['password']

    if !email
      return [400, 'no email']
    elsif !password
      return [400, 'no password']
    elsif email.length > 256
      return [400, 'email address exceeds maximum length']
    elsif password.length > 100
      return [400, 'password exceeds maximum length']
    elsif Db.user_exists?(email)
      return [400, 'already registered']
    end

    if Db.create_user(email, password)
      return [200, 'ok']
    else
      return [500, 'internal error']
    end
  end

  # Reset a password
  post '/reset_password' do
    email = params['email']

    if !email
      return [400, 'no email address']
    elsif !Db.user_exists?(email)
      return [400, 'unknown email address']
    end

    unless password = Db.reset_password(email)
      return [500, 'internal error']
    end

    if Utilities.send_reset_email(email, password)
      return [200, 'ok']
    else
      return [500, 'internal error']
    end
  end

  # Change a user's email address
  post '/change_email' do
    email = protected!
    new_email = params['new_email']

    if !Db.user_exists?(email)
      return [400, 'bad email address']
    elsif !new_email
      return [400, 'no new email address']
    elsif new_email.length > 256
      return [400, 'email address exceeds maximum length']
    elsif Db.user_exists?(new_email)
      return [400, 'new email already registered']
    end

    Db.change_email(email, new_email)
    return [200, 'ok']
  end

  # Change a user's password
  post '/change_password' do
    email = protected!
    new_password = params['new_password']

    if !Db.user_exists?(email)
      return [400, 'bad email address']
    elsif !new_password
      return [400, 'no password']
    elsif password.length > 100
      return [400, 'password exceeds maximum length']
    end

    Db.change_password(email, new_password)
    return [200, 'ok']
  end

  # Send a message
  post '/send' do
    sender_email   = protected!
    receiver_email = params['receiver']
    message        = params['message']
    timestamp      = params['timestamp']

    if !Db.user_exists?(sender_email)
      return [400, 'bad user id']
    elsif !receiver_email
      return [400, 'no receiver email']
    elsif !Db.user_exists?(receiver_email)
      return [400, 'bad receiver email']
    elsif !timestamp
      return [400, 'no timestamp']
    elsif !message
      return [400, 'no message']
    end

    now = Time.now.utc.to_i
    unless (timestamp.to_i > now - 60*5) && (timestamp.to_i < now + 60)
      return [400, 'bad timestamp']
    end

    if Utilities.send_message(sender_email, receiver_email, message, timestamp)
      return [200, 'ok']
    else
      return [500, 'internal error']
    end
  end

  # Poll for new messages
  post '/poll' do
    email = protected!
    unless $messages[email]
      return [200, [].to_json]
    end
    return [200, $messages.delete(email).to_json]
  end
end
