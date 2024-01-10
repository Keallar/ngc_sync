# frozen_string_literal: true

every 1.hour do
  runner 'NgcSync::Synchronization.perform', output: 'log/cron_log.log'
end
