# Simple Ruby Chat Server

This is a very simple chat server that I created while prototyping an iOS chat application. It uses polling to get new messages, and all API calls are done over HTTP.

The backend of this system is a Postgres database.

### Postgres Database Setup

Creating a Postgres user:
```
sudo -i
su - postgres
psql
CREATE USER chat WITH PASSWORD 'test_password';
GRANT usage on schema public to chat;
CREATE DATABASE chat;
GRANT ALL PRIVILEGES ON DATABASE chat to chat;
\q
```

Creating the database table:
```
psql -h 127.0.0.1 -d chat -U chat -W
CREATE TABLE users (
      email varchar(256),
      password varchar(100),
      salt varchar(100),
      shared_secret varchar(100));
CREATE INDEX email_idx ON users (email);
\q
```
