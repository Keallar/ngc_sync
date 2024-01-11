# frozen_string_literal: true

require_relative '../lib/ngc_sync'

ENV.each { |k, v| env(k, v) }

set :path, ENV['PWD']

job_type(:rake,
         'cd :path && ('\
           "echo \"$(date '+%Y-%m-%d %H:%M:%S') <:tag> started\" && "\
           'bundle exec rake :task && '\
           "echo \"$(date '+%Y-%m-%d %H:%M:%S') <:tag> finished\""\
           ') :output')

every '* */1 * * *' do
  rake 'ngc_sync:run', output: 'log/cron.log', tag: 'NgcSync::Synchronization run'
end
