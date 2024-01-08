# frozen_string_literal: true

$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'dotenv/load'
require 'dry/monads'
require 'googleauth'
require 'googleauth/stores/redis_token_store'
require 'googleauth/stores/file_token_store'
require 'google/apis/calendar_v3'
require 'notion-ruby-client'
require 'redis'
require 'yaml'
require 'logger'
require 'ngc_sync/config'
require 'ngc_sync/adapters/notion_client'
require 'ngc_sync/adapters/google_client'
require 'ngc_sync/synchronization'

# Main namespace
module NgcSync
end
