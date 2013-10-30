require 'securerandom'
require 'pg'
require 'digest/sha1'

class Db
  @conn = PG.connect(
    :hostaddr => '127.0.0.1',
    :port     => 5432,
    :dbname   => 'chat',
    :user     => 'chat',
    :password => 'test_password')

  class << self
    def hash_password(password, salt)
      return Digest::SHA1.hexdigest(password + salt)
    end
    private :hash_password

    def user_exists?(email)
      email_safe = @conn.escape_string(email)
      query = "select count(email) from users where email='#{email_safe}'"
      begin
        result = @conn.exec(query)
        return result[0]['count'].to_i > 0
      rescue
        return false
      end
    end

    def get_shared_secret(email)
      email_safe = @conn.escape_string(email)
      query = "select shared_secret from users where email='#{email_safe}'"
      begin
        result = @conn.exec(query)
        return result[0]['shared_secret'].to_s
      rescue
        return nil
      end
    end

    def create_user(email, password)
      email_safe = @conn.escape_string(email)
      if user_exists?(email_safe)
        return false
      end

      salt = SecureRandom.hex
      shared_secret = SecureRandom.hex
      hash = hash_password(password, salt)

      begin
        query = "INSERT INTO users (email, password, salt, shared_secret) 
          VALUES ('#{email_safe}', '#{hash}', '#{salt}', '#{shared_secret}')"
        result = @conn.exec(query)
        return shared_secret
      rescue
        return false
      end
    end

    def verify_password(email, password)
      email_safe = @conn.escape_string(email)
      query = "select password, salt from users where email='#{email_safe}'"

      results = @conn.exec(query)

      unless results.count == 1
        return false
      end

      hash, salt = results[0].values
      if hash && salt
        return hash_password(password, salt) == hash
      else
        return false
      end
    end

    def change_password(email, password)
      email_safe = @conn.escape_string(email)
      unless user_exists?(email_safe)
        return false
      end

      salt = SecureRandom.hex
      hash = hash_password(password, salt)

      begin
        query = "UPDATE users SET (password, salt) = 
          ('#{hash}', '#{salt}') WHERE email='#{email_safe}'"
        result = @conn.exec(query)
        return true
      rescue
        return false
      end
    end

    def reset_shared_secret(email)
      email_safe = @conn.escape_string(email) 
      unless user_exists?(email_safe)
        return false
      end

      shared_secret = SecureRandom.hex

      begin
        query = "UPDATE users SET (shared_secret) = 
          ('#{shared_secret}') WHERE email='#{email_safe}'"
        result = @conn.exec(query)
        return shared_secret
      rescue
        return nil
      end
    end

    def reset_password(email)
      email_safe = @conn.escape_string(email) 
      unless user_exists?(email_safe)
        return false
      end

      password = SecureRandom.hex(5)
      salt = SecureRandom.hex
      hash = hash_password(password, salt)

      begin
        query = "UPDATE users SET (password, salt) = 
          ('#{hash}', '#{salt}') WHERE email='#{email_safe}'"
        result = @conn.exec(query)
        return password
      rescue
        return nil
      end
    end

    def change_email(email, new_email)
      email_safe = @conn.escape_string(email)
      new_email_safe = @conn.escape_string(new_email)
      unless user_exists?(email)
        return false
      end

      begin
        query = "UPDATE users SET (email) = 
          ('#{new_email_safe}') WHERE email='#{email_safe}'"
        result = @conn.exec(query)
        return true
      rescue
        return false
      end
    end

  end
end
