# Legal App

A Ruby on Rails application for managing lawsuits, provisions, and legal documents with commenting capabilities.

## Tech Stack

- **Ruby version**: 3.3.5
- **Rails version**: 7.2.2
- **Database**: 
  - Development: SQLite3
  - Production: PostgreSQL
- **Styling**: Tailwind CSS
- **Authentication**: Devise
- **Authorization**: Pundit

## Prerequisites

- Ruby 3.3.5 (use rbenv or rvm)
- Node.js and Yarn
- Bundler 2.5+
- SQLite3 (for development)
- PostgreSQL (for production/Docker)

## Setup Instructions

### Option 1: Local Development (Recommended for Code Changes)

This is the fastest way to develop and see changes immediately.

1. **Install dependencies**
   ```bash
   bundle install
   ```

2. **Setup database**
   ```bash
   rails db:prepare
   ```

3. **Start the server**
   ```bash
   rails server
   # Or use the dev script for Tailwind CSS hot reload
   bin/dev
   ```

4. **Access the app**
   - Open http://localhost:3000

### Option 2: Docker Setup (Production-like Environment)

Use this to test the production configuration locally.

1. **Prerequisites**
   - Docker Desktop installed and running
   - PostgreSQL running locally on port 5432

2. **Configure environment**
   - Copy `.env.sample` to `.env` and set values:
   ```bash
   RAILS_ENV=production
   DB_HOST=host.docker.internal
   DB_PORT=5432
   DB_USERNAME=legalapp
   DB_PASSWORD=legalapp
   SECRET_KEY_BASE=<generate with 'rails secret'>
   ```

3. **Start PostgreSQL locally** (if not already running)
   ```bash
   brew services start postgresql@14
   ```

4. **Create database user** (first time only)
   ```bash
   psql postgres
   CREATE USER legalapp WITH PASSWORD 'legalapp';
   ALTER USER legalapp CREATEDB;
   \q
   ```

5. **Build and run with Docker**
   ```bash
   docker-compose build
   docker-compose up
   ```

6. **Setup database** (first time only)
   ```bash
   docker-compose run --rm app rails db:create db:migrate
   ```

7. **Access the app**
   - Open http://localhost:8080

## Setting Up on a New Machine (Laptop)

Follow these steps to set up the project on a new computer:

1. **Install Ruby 3.3.5**
   ```bash
   # Using rbenv
   rbenv install 3.3.5
   rbenv local 3.3.5
   ```

2. **Install system dependencies**
   ```bash
   # macOS
   brew install node yarn postgresql@14 sqlite3
   ```

3. **Clone and setup**
   ```bash
   git clone <your-repo-url>
   cd legal_app
   bundle install
   rails db:prepare
   ```

4. **Run the app**
   ```bash
   bin/dev
   ```

## Key Features

- **Lawsuit Management**: Create, view, edit, and track lawsuits
- **Provisions**: Manage legal provisions and documentation
- **Commenting System**: Add comments to lawsuits
- **User Authentication**: Secure login with Devise
- **Authorization**: Role-based access control with Pundit
- **Responsive Design**: Tailwind CSS for mobile-friendly interface

## Development Commands

- `rails server` - Start Rails server on port 3000
- `bin/dev` - Start Rails + Tailwind CSS watcher
- `rails console` - Open Rails console
- `rails db:migrate` - Run database migrations
- `rails db:reset` - Reset database
- `rails test` - Run test suite
- `rubocop` - Check code style
- `brakeman` - Security vulnerability scan

## Docker Commands

- `docker-compose build` - Build the Docker image
- `docker-compose up` - Start all services
- `docker-compose down` - Stop all services
- `docker-compose run --rm app rails c` - Rails console in Docker
- `docker-compose logs -f app` - View logs

## User Accounts & Password Reset

### Default Users
The development database includes these test accounts:

| Email | Role | Default Password (after reset) |
|-------|------|-------------------------------|
| ergoni@example.com | admin_developer | admin123 |
| admini_ligjor@kosovotelecom.com | admin | admin123 |
| operator@example.com | operator | admin123 |

### Forgot Password?

> ⚠️ **Security Note**: The `reset_password.sh` script is for **LOCAL DEVELOPMENT ONLY**. It's excluded from Git and Docker for security. Never use it in production!

**Quick reset using the script (development only):**
```bash
./reset_password.sh ergoni@example.com newpassword123
```

**Manual reset via Rails console:**
```bash
rails console
# Then run:
user = User.find_by(email: 'ergoni@example.com')
user.password = 'newpassword'
user.password_confirmation = 'newpassword'
user.save
```

**List all users:**
```bash
rails runner "User.all.each { |u| puts '#{u.email} - #{u.role}' }"
```

## Troubleshooting

### "Operation not permitted" errors with PostgreSQL
- Make sure PostgreSQL is running: `brew services list`
- Start it if needed: `brew services start postgresql@14`
- Check it's accessible: `pg_isready -h localhost -p 5432`

### Docker can't connect to database
- Verify PostgreSQL is running locally
- Check `DB_HOST=host.docker.internal` in `.env`
- Ensure PostgreSQL accepts TCP connections on port 5432

### Tailwind CSS not updating
- Make sure you're using `bin/dev` instead of `rails server`
- Check that `tailwindcss-rails` gem is installed

### Can't login / Forgot password
- Use `./reset_password.sh [email] [new_password]`
- Or manually via `rails console` (see User Accounts section above)