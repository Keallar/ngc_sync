# frozen_string_literal: true

require './lib/ngc_sync'

desc 'Open an irb session preloaded with the environment'
task :console do
  require 'irb'

  ARGV.clear
  IRB.start
end

namespace :ngc_sync do
  desc 'Run synchronization'
  task :run do
    NgcSync::Synchronization.perform
  end
end
