# Use the lightweight Ruby 3.3 Alpine image
FROM ruby:3.3-alpine

# Define build-time arguments
ARG RAILS_ENV
ARG DB_HOST
ARG DB_PORT
ARG DB_USERNAME
ARG DB_PASSWORD
ARG SECRET_KEY_BASE

# Set the environment variables
ENV RAILS_ENV=${RAILS_ENV}
ENV DB_HOST=${DB_HOST}
ENV DB_PORT=${DB_PORT}
ENV DB_USERNAME=${DB_USERNAME}
ENV DB_PASSWORD=${DB_PASSWORD}
ENV SECRET_KEY_BASE=${SECRET_KEY_BASE}

# Install required dependencies
RUN apk add --no-cache build-base postgresql-dev nodejs yarn tzdata yaml-dev libc6-compat

# Set the working directory
WORKDIR /app

# Copy Gemfile and install gems
COPY Gemfile Gemfile.lock ./
RUN bundle install --without development test --jobs 4 --retry 3

# Copy the entire application
COPY . .

# Precompile assets and migrate the database using the RAILS_ENV environment variable
RUN bundle exec rake assets:precompile RAILS_ENV=$RAILS_ENV
RUN bundle exec rake db:migrate RAILS_ENV=$RAILS_ENV DB_HOST=$DB_HOST DB_PORT=$DB_PORT DB_USERNAME=$DB_USERNAME DB_PASSWORD=$DB_PASSWORD SECRET_KEY_BASE=$SECRET_KEY_BASE

# Expose port 3000 for the Rails app
EXPOSE 3000

# Start the Rails server
CMD ["rails", "server", "-b", "0.0.0.0", "-p", "3000"]
