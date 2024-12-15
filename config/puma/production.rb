# This configuration file will be evaluated by Puma. The top-level methods that
threads_count = ENV.fetch("RAILS_MAX_THREADS", 5)
threads threads_count, threads_count

# Specifies the `port` that Puma will listen on to receive requests; default is 3000.
port ENV.fetch("PORT", 3000)

# Env
workers Integer(ENV.fetch("WEB_CONCURRENCY", 6))

preload_app!
# Allow puma to be restarted by `bin/rails restart` command.
plugin :tmp_restart

# Specify the PID file. Defaults to tmp/pids/server.pid in development.
# In other environments, only set the PID file if requested.
app_dir = "/home/admin1/app"
bind "unix://#{app_dir}/puma.sock"
pidfile "#{app_dir}/puma.pid"
state_path "#{app_dir}/puma.state"
directory "#{app_dir}/"

stdout_redirect "#{app_dir}/log/puma.stdout.log", "#{app_dir}/log/puma.stderr.log", true

activate_control_app "unix://#{app_dir}/pumactl.sock"

on_worker_boot do
  ActiveRecord::Base.establish_connection
end
