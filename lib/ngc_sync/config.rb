# frozen_string_literal: true

# Main namespace
module NgcSync
  VERSION = '0.1.0'
  NOTION_API_TOKEN = ENV['NOTION_API_TOKEN']
  GOOGLE_API_TOKEN = ENV['GOOGLE_API_TOKEN']
  GOOGLE_CLIENT_ID = ENV['GOOGLE_CLIENT_ID']
  GOOGLE_CLIENT_SECRET = ENV['GOOGLE_CLIENT_SECRET']
  GOOGLE_USER_ID = ENV['GOOGLE_USER_ID']
  CONFIG = YAML.load_file('config.yml')

  def self.logger
    @logger ||= Logger.new('log/app.log')
  end
end
