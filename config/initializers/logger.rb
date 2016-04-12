class Application

#	class Logger::SimpleFormatter
#               def call(severity, timestamp, progname, msg)
#                       msg = "#{String === msg ? msg : msg.inspect}"
#                       "[#{timestamp.to_s(:log)}] #{"[%5s]"% severity.upcase} #{msg}\n"
#               end
#	end

        Logger.class_eval { alias :write :'<<' }
        access_log = File.join(File.dirname(File.expand_path(__FILE__)),'..', '..', 'log','rack_stdout.log')
        $logger = Logger.new(access_log, 10, 10490000) #rollover after 10MB
        
        $error_logger = File.new(File.join(File.dirname(File.expand_path(__FILE__)),'..','..','log','rack_stderr.log'),"a+")
        $error_logger.sync = true

        configure do
                use Rack::CommonLogger, $logger
                set :logging, nil
                #enable :logging
        end

        before do
                env["rack.logger"] = $logger
                env["rack.errors"] = $error_logger
        end
end

