# frozen_string_literal: true

module NgcSync
  module Adapters
    # Adapter for notion client
    class NotionClient
      attr_reader :client, :config

      def initialize
        @config = CONFIG['notion']
        @client = init_client
      end

      def db_calendar_dates_with_title
        db_calendar_objects.map do |obj|
          title = db_calendar_title(obj)
          date = db_calendar_date(obj)
          { 'summary' => title }.merge(date)
        end
      end

      def db_calendar_objects
        response = client.database_query(database_id: config['database_id'])
        results = response['results']
        results.reject { |obj| obj.dig('properties', 'Date', 'date').nil? }
      rescue Notion::Api::Errors::NotionError => e
        puts 'Invalid database id'
        NgcSync.logger.error e.message
        NgcSync.logger.error e.backtrace&.join("\n")
      end

      private
      
      def db_calendar_title(obj)
        obj.dig('properties', 'Name', 'title').first.dig('text', 'content')
      end

      def db_calendar_date(obj)
        obj.dig('properties', 'Date', 'date')
      end

      def init_client
        Notion::Client.new(token: NOTION_API_TOKEN)
      end

      # def method_missing(method_name, *args, &block)
      #   client.respond_to?(method_name) ? client.send(method_name, *args, &block) : super
      # end
      #
      # def respond_to_missing?(method_name, include_private = false)
      #   super unless client.respond_to?(method_name)
      # end
    end
  end
end
