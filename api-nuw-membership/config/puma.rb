root = "#{Dir.getwd}"

activate_control_app "tcp://0.0.0.0:9294",{ no_token: true }
#bind "unix:///tmp/puma.pumatra.sock"
bind "tcp://0.0.0.0:9292"
pidfile "#{root}/pids/puma.pid"
rackup "#{root}/config.ru"
state_path "#{root}/pids/puma.state"

# This is a hastle for debugging, where does stdout go when not set?
#stdout_redirect "#{root}/log/puma_stdout.log", "#{root}/log/puma_stderr.log", true
