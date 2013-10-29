# Production Server

This is the production server.

Creating a Postgres user:
  sudo -i
  su - postgres
  psql
  CREATE USER chat WITH PASSWORD 'test_password';
  GRANT usage on schema public to chat;
  CREATE DATABASE chat;
  GRANT ALL PRIVILEGES ON DATABASE chat to chat;
  \q

Creating the database table in Postgres:
  psql -h 127.0.0.1 -d chat -U chat -W
  CREATE TABLE users (
      email varchar(256),
      password varchar(100),
      salt varchar(100));
  \q

  CREATE INDEX email_idx ON users (email);
