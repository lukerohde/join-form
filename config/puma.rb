root = "#{Dir.getwd}"

activate_control_app "tcp://0.0.0.0:9293",{ no_token: true }
#bind "unix:///tmp/puma.pumatra.sock"
bind "tcp://0.0.0.0:9292"
pidfile "#{root}/pids/puma.pid"
rackup "#{root}/config.ru"
state_path "#{root}/pids/puma.state"
stdout_redirect "#{root}/log/puma_stdout.log", "#{root}/log/puma_stderr.log", true
