SuckerPunch.exception_handler = -> (ex, klass, args) { ExceptionNotifier.notify_exception(ex) }
require 'sucker_punch/async_syntax'

Rails.application.configure do
    config.active_job.queue_adapter = :sucker_punch
end