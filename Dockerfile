# Use the lightweight Ruby 3.3 Alpine image
FROM ruby:3.3-alpine

# Install required dependencies
RUN apk add --no-cache build-base postgresql-dev nodejs yarn tzdata

# Set the working directory
WORKDIR /app

# Copy Gemfile and install gems
COPY Gemfile Gemfile.lock ./
RUN bundle install --without development test --jobs 4 --retry 3

# Copy the entire application
COPY . .

# Precompile assets and migrate the database
RUN bundle exec rake assets:precompile
RUN bundle exec rake db:migrate

# Expose port 3000 for the Rails app
EXPOSE 3000

# Start the Rails server
CMD ["rails", "server", "-b", "0.0.0.0", "-p", "3000"]
