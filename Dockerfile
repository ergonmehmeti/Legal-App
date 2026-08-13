# Use the lightweight Ruby 3.3 Alpine image
FROM ruby:3.3-alpine

# Define build-time arguments
ARG RAILS_ENV
ARG DB_HOST
ARG DB_PORT
ARG DB_USERNAME
ARG DB_PASSWORD
ARG SECRET_KEY_BASE
ARG CREATE_DATABASE

# Set the environment variables
ENV RAILS_ENV=${RAILS_ENV}
ENV DB_HOST=${DB_HOST}
ENV DB_PORT=${DB_PORT}
ENV DB_USERNAME=${DB_USERNAME}
ENV DB_PASSWORD=${DB_PASSWORD}
ENV SECRET_KEY_BASE=${SECRET_KEY_BASE}

# Install dependencies using HTTP Alpine repos, then refresh certificate store
RUN set -eux; \
    echo "http://dl-cdn.alpinelinux.org/alpine/v3.21/main" > /etc/apk/repositories; \
    echo "http://dl-cdn.alpinelinux.org/alpine/v3.21/community" >> /etc/apk/repositories; \
    apk update; \
    apk add --no-cache ca-certificates openssl build-base postgresql-dev nodejs yarn tzdata yaml-dev libc6-compat; \
    update-ca-certificates

# Set the working directory
WORKDIR /app

# Copy Gemfile and install gems
COPY Gemfile Gemfile.lock ./
RUN sed -i 's|https://rubygems.org|http://rubygems.org|g' Gemfile Gemfile.lock && \
    bundle config set without 'development test' && \
    bundle install --jobs 4 --retry 3

# Copy the entire application
COPY . .

# Precompile assets
RUN bundle exec rake assets:precompile RAILS_ENV=$RAILS_ENV

# Conditionally create the database if CREATE_DATABASE is set to true
RUN if [ "${CREATE_DATABASE}" = "true" ]; then bundle exec rake db:create RAILS_ENV=$RAILS_ENV DB_HOST=$DB_HOST DB_PORT=$DB_PORT DB_USERNAME=$DB_USERNAME DB_PASSWORD=$DB_PASSWORD SECRET_KEY_BASE=$SECRET_KEY_BASE; fi

# Migrate the database
RUN bundle exec rake db:migrate RAILS_ENV=$RAILS_ENV DB_HOST=$DB_HOST DB_PORT=$DB_PORT DB_USERNAME=$DB_USERNAME DB_PASSWORD=$DB_PASSWORD SECRET_KEY_BASE=$SECRET_KEY_BASE

# Expose port 3000 for the Rails app
EXPOSE 3000

# Start the Rails server
CMD ["rails", "server", "-b", "0.0.0.0", "-p", "3000"]